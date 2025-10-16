using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PropertyFlipperAPI.Services
{
    public class OpenAIService
    {
        private readonly string _apiKey;
        private readonly HttpClient _httpClient;
        private readonly ILogger<OpenAIService> _logger;

        public OpenAIService(IConfiguration configuration, ILogger<OpenAIService> logger)
        {
            _apiKey = configuration["OpenAI:ApiKey"] ?? throw new InvalidOperationException("OpenAI API key not configured");
            _httpClient = new HttpClient
            {
                Timeout = TimeSpan.FromSeconds(90) // Increased timeout for OpenAI Vision API
            };
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
            _logger = logger;
        }

        public async Task<List<PaymentScheduleItem>> AnalyzePaymentScheduleAsync(byte[] imageData)
        {
            try
            {
                // Convert image to base64
                var base64Image = Convert.ToBase64String(imageData);
                var imageDataUrl = $"data:image/jpeg;base64,{base64Image}";

                // Prepare the request payload
                var requestBody = new
                {
                    model = "gpt-4o",
                    messages = new object[]
                    {
                        new
                        {
                            role = "system",
                            content = "You are a payment schedule analyzer. Extract all payment dates, descriptions, and amounts from the provided image. Return ONLY a valid JSON array with no additional text or formatting. Each object should have: date (ISO 8601 format), description (string), and amount (number)."
                        },
                        new
                        {
                            role = "user",
                            content = new object[]
                            {
                                new
                                {
                                    type = "text",
                                    text = "Please analyze this payment schedule image and extract all payment information. Return the data as a JSON array with objects containing: date (in ISO 8601 format like '2025-01-15'), description (payment description), and amount (payment amount as a number). Return ONLY the JSON array, no additional text."
                                },
                                new
                                {
                                    type = "image_url",
                                    image_url = new
                                    {
                                        url = imageDataUrl
                                    }
                                }
                            }
                        }
                    },
                    max_tokens = 4000,  // Increased to allow for longer payment schedules
                    temperature = 0.1
                };

                var jsonContent = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                _logger.LogInformation("Sending request to OpenAI API...");

                // Make the API request
                var response = await _httpClient.PostAsync("https://api.openai.com/v1/chat/completions", content);
                var responseContent = await response.Content.ReadAsStringAsync();
                
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"OpenAI API error: {response.StatusCode} - {responseContent}");
                    throw new Exception($"OpenAI API request failed: {response.StatusCode} - {responseContent}");
                }

                _logger.LogInformation($"OpenAI Response: {responseContent.Substring(0, Math.Min(500, responseContent.Length))}...");

                var responseObject = JsonSerializer.Deserialize<OpenAIResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (responseObject?.Choices == null || responseObject.Choices.Length == 0)
                {
                    _logger.LogError($"Invalid OpenAI response structure. Response: {responseContent}");
                    throw new Exception("No valid response from OpenAI API. The response format was unexpected.");
                }

                var messageContent = responseObject.Choices[0].Message.Content;
                
                _logger.LogInformation($"OpenAI message content: {messageContent}");
                
                // Clean up the response (remove markdown code blocks if present)
                var cleanedContent = messageContent.Trim();
                if (cleanedContent.StartsWith("```json"))
                {
                    cleanedContent = cleanedContent.Substring(7);
                }
                if (cleanedContent.StartsWith("```"))
                {
                    cleanedContent = cleanedContent.Substring(3);
                }
                if (cleanedContent.EndsWith("```"))
                {
                    cleanedContent = cleanedContent.Substring(0, cleanedContent.Length - 3);
                }
                cleanedContent = cleanedContent.Trim();

                _logger.LogInformation($"Cleaned content to parse: {cleanedContent}");

                // Parse the JSON response
                try
                {
                    var paymentItems = JsonSerializer.Deserialize<List<PaymentScheduleItem>>(cleanedContent, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                    return paymentItems ?? new List<PaymentScheduleItem>();
                }
                catch (JsonException ex)
                {
                    _logger.LogError($"Failed to parse JSON. Content: {cleanedContent}");
                    _logger.LogError($"JSON Parse Error: {ex.Message}");
                    throw new Exception($"Failed to parse OpenAI response. The AI returned incomplete or invalid JSON. Try with a smaller/clearer image. Error: {ex.Message}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error analyzing payment schedule with OpenAI");
                throw;
            }
        }

        public async Task<AIValuationResult> ValuatePropertyAsync(
            PropertyValuationData property,
            List<ComparablePropertyData> comparables,
            List<AuctionDataForValuation> auctions)
        {
            try
            {
                _logger.LogInformation($"Starting AI property valuation for: {property.Location}");

                // Build the prompt with property data, comparables, and auctions
                var promptText = BuildValuationPrompt(property, comparables, auctions);

                var requestBody = new
                {
                    model = "gpt-4o",
                    messages = new object[]
                    {
                        new
                        {
                            role = "system",
                            content = "You are an expert real estate appraiser and market analyst. Analyze the provided property details, comparable properties, and auction data to provide an accurate market valuation. Return your response as a JSON object with the following structure: {\"estimatedPrice\": number, \"priceRangeLow\": number, \"priceRangeHigh\": number, \"confidence\": number (0-1), \"reasoning\": string (brief 2-3 sentences), \"marketTrends\": string (brief current market summary), \"topComparables\": array of 5 most relevant properties with {\"name\", \"location\", \"bedrooms\", \"bathrooms\", \"squareFeet\", \"price\", \"status\"}}. Return ONLY the JSON object, no additional text."
                        },
                        new
                        {
                            role = "user",
                            content = promptText
                        }
                    },
                    max_tokens = 2000,
                    temperature = 0.3
                };

                var jsonContent = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                _logger.LogInformation("Sending valuation request to OpenAI API...");

                var response = await _httpClient.PostAsync("https://api.openai.com/v1/chat/completions", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"OpenAI API error: {response.StatusCode} - {responseContent}");
                    throw new Exception($"OpenAI API request failed: {response.StatusCode}");
                }

                var responseObject = JsonSerializer.Deserialize<OpenAIResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (responseObject?.Choices == null || responseObject.Choices.Length == 0)
                {
                    _logger.LogError($"Invalid OpenAI response. Response: {responseContent}");
                    throw new Exception("No valid response from OpenAI API");
                }

                var messageContent = responseObject.Choices[0].Message.Content;
                _logger.LogInformation($"OpenAI valuation response: {messageContent}");

                // Clean up the response
                var cleanedContent = messageContent.Trim();
                if (cleanedContent.StartsWith("```json"))
                {
                    cleanedContent = cleanedContent.Substring(7);
                }
                if (cleanedContent.StartsWith("```"))
                {
                    cleanedContent = cleanedContent.Substring(3);
                }
                if (cleanedContent.EndsWith("```"))
                {
                    cleanedContent = cleanedContent.Substring(0, cleanedContent.Length - 3);
                }
                cleanedContent = cleanedContent.Trim();

                // Parse the JSON response
                var valuationResult = JsonSerializer.Deserialize<AIValuationResult>(cleanedContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                return valuationResult ?? throw new Exception("Failed to parse valuation result");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error performing AI valuation");
                throw;
            }
        }

        private string BuildValuationPrompt(
            PropertyValuationData property,
            List<ComparablePropertyData> comparables,
            List<AuctionDataForValuation> auctions)
        {
            var prompt = new StringBuilder();
            
            prompt.AppendLine("Please valuate the following property based on market data:");
            prompt.AppendLine();
            prompt.AppendLine("TARGET PROPERTY:");
            prompt.AppendLine($"Location: {property.Location}");
            prompt.AppendLine($"Bedrooms: {property.Bedrooms}");
            prompt.AppendLine($"Bathrooms: {property.Bathrooms}");
            prompt.AppendLine($"Square Feet: {property.SquareFeet}");
            prompt.AppendLine($"Year Built: {property.YearBuilt}");
            prompt.AppendLine($"Property Type: {property.PropertyType}");
            prompt.AppendLine();

            if (comparables.Any())
            {
                prompt.AppendLine($"COMPARABLE PROPERTIES ({comparables.Count}):");
                foreach (var comp in comparables.Take(30))
                {
                    prompt.AppendLine($"- {comp.Name} | {comp.Location} | {comp.Bedrooms}bed/{comp.Bathrooms}bath | {comp.SquareFeet}sqft | Built:{comp.YearBuilt} | Price: ${comp.Price:N0} | Status: {comp.Status}");
                }
                prompt.AppendLine();
            }

            if (auctions.Any())
            {
                prompt.AppendLine($"AUCTION DATA ({auctions.Count}):");
                foreach (var auction in auctions.Take(30))
                {
                    prompt.AppendLine($"- {auction.PropertyName} | {auction.Location} | {auction.Bedrooms}bed/{auction.Bathrooms}bath | {auction.SquareFeet}sqft | Current Price: ${auction.CurrentPrice:N0} | Status: {auction.Status} | Bids: {auction.BidCount}");
                }
                prompt.AppendLine();
            }

            prompt.AppendLine("Based on this market data, provide:");
            prompt.AppendLine("1. Accurate estimated market value");
            prompt.AppendLine("2. Realistic price range (low and high)");
            prompt.AppendLine("3. Confidence score (0-1 based on data quality)");
            prompt.AppendLine("4. Brief reasoning (2-3 sentences explaining key factors)");
            prompt.AppendLine("5. Current market trends summary");
            prompt.AppendLine("6. Select and return the 5 most relevant comparable properties from the data above");

            return prompt.ToString();
        }

        public async Task<BrokerAIResponse> GetBrokerResponseAsync(List<BrokerConversationMessage> conversationHistory, string availableLocations, string userPreferences)
        {
            try
            {
                _logger.LogInformation("Getting AI broker response");

                // Build conversation messages for OpenAI
                var messages = new List<object>
                {
                    new
                    {
                        role = "system",
                        content = @"You are 'My Broker', a friendly and helpful real estate assistant. Your job is to help users find their perfect property through natural conversation.

CRITICAL: You MUST respond with ONLY valid JSON. No other text before or after the JSON.

IMPORTANT RULES:
1. Be conversational, warm, and friendly. Use emojis occasionally 😊
2. Ask ONE question at a time
3. When asking questions, provide multiple choice options in your response
4. Keep track of what you've learned about the user
5. NEVER end the conversation - always offer to help more or ask follow-up questions
6. When showing properties without auctions, ask if they want to see other options
7. After recommendations, ask if they want to refine their search or see more properties

Available locations in our database: " + availableLocations + @"

You MUST respond with ONLY this JSON format (no additional text):
{
  ""message"": ""Your friendly message to the user"",
  ""nextAction"": ""ask_question"" or ""show_properties"" or ""continue_conversation"",
  ""questionType"": ""budget"" or ""location"" or ""bedrooms"" or ""bathrooms"" or ""propertyType"" or null,
  ""options"": [""Option 1"", ""Option 2"", ...] or null
}

Current user preferences collected: " + userPreferences
                    }
                };

                // Add conversation history
                foreach (var msg in conversationHistory)
                {
                    messages.Add(new
                    {
                        role = msg.Role.ToLower(),
                        content = msg.Content
                    });
                }

                var requestBody = new
                {
                    model = "gpt-4o",
                    messages = messages.ToArray(),
                    max_tokens = 500,
                    temperature = 0.7,
                    response_format = new { type = "json_object" }
                };

                var jsonContent = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync("https://api.openai.com/v1/chat/completions", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"OpenAI API error: {response.StatusCode} - {responseContent}");
                    throw new Exception($"OpenAI API request failed");
                }

                var responseObject = JsonSerializer.Deserialize<OpenAIResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (responseObject?.Choices == null || responseObject.Choices.Length == 0)
                {
                    throw new Exception("No response from OpenAI");
                }

                var messageContent = responseObject.Choices[0].Message.Content.Trim();
                _logger.LogInformation($"Raw AI response: {messageContent.Substring(0, Math.Min(500, messageContent.Length))}");

                // Clean markdown if present
                if (messageContent.StartsWith("```json"))
                    messageContent = messageContent.Substring(7);
                if (messageContent.StartsWith("```"))
                    messageContent = messageContent.Substring(3);
                if (messageContent.EndsWith("```"))
                    messageContent = messageContent.Substring(0, messageContent.Length - 3);
                messageContent = messageContent.Trim();

                _logger.LogInformation($"Cleaned AI response: {messageContent.Substring(0, Math.Min(500, messageContent.Length))}");

                BrokerAIResponse brokerResponse;
                try
                {
                    brokerResponse = JsonSerializer.Deserialize<BrokerAIResponse>(messageContent, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    }) ?? throw new Exception("Failed to parse broker response");
                }
                catch (JsonException jsonEx)
                {
                    _logger.LogError($"JSON parsing failed. Content starts with: {messageContent.Substring(0, Math.Min(100, messageContent.Length))}");
                    _logger.LogError(jsonEx, "JSON deserialization error");
                    
                    // Return a friendly fallback response if AI didn't return proper JSON
                    return new BrokerAIResponse
                    {
                        Message = "Great! Let me help you find the perfect property. What's your budget range?",
                        NextAction = "ask_question",
                        QuestionType = "budget",
                        Options = new List<string> { "Under $200k", "$200k - $400k", "$400k - $600k", "$600k - $800k", "Above $800k" }
                    };
                }

                return brokerResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting broker AI response");
                throw;
            }
        }

        // OpenAI API response models
        private class OpenAIResponse
        {
            [JsonPropertyName("choices")]
            public Choice[]? Choices { get; set; }
        }

        private class Choice
        {
            [JsonPropertyName("message")]
            public Message Message { get; set; } = new Message();
        }

        private class Message
        {
            [JsonPropertyName("content")]
            public string Content { get; set; } = string.Empty;
        }
    }

    public class PaymentScheduleItem
    {
        public string Date { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Amount { get; set; }
    }

    // Property Valuation Models
    public class PropertyValuationData
    {
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
        public string PropertyType { get; set; } = string.Empty;
    }

    public class ComparablePropertyData
    {
        public string Name { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
        public string Type { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    public class AuctionDataForValuation
    {
        public string PropertyName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public decimal CurrentPrice { get; set; }
        public string Status { get; set; } = string.Empty;
        public int BidCount { get; set; }
    }

    public class AIValuationResult
    {
        public decimal EstimatedPrice { get; set; }
        public decimal PriceRangeLow { get; set; }
        public decimal PriceRangeHigh { get; set; }
        public decimal Confidence { get; set; }
        public string Reasoning { get; set; } = string.Empty;
        public string MarketTrends { get; set; } = string.Empty;
        public List<TopComparable> TopComparables { get; set; } = new List<TopComparable>();
    }

    public class TopComparable
    {
        public string Name { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public decimal Price { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    // AI Broker Conversation Models
    public class BrokerConversationMessage
    {
        public string Role { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }

    public class BrokerAIResponse
    {
        public string Message { get; set; } = string.Empty;
        public string NextAction { get; set; } = string.Empty; // ask_question, show_properties, continue_conversation
        public string? QuestionType { get; set; }
        public List<string>? Options { get; set; }
    }
}

