using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Services
{
    public class AuctionWebSocketManager
    {
        private readonly ConcurrentDictionary<string, HashSet<WebSocket>> _auctionConnections = new();
        private readonly ConcurrentDictionary<WebSocket, string> _socketToAuction = new();

        public async Task HandleWebSocketAsync(WebSocket webSocket, HttpContext context)
        {
            var buffer = new byte[1024 * 4];
            string? currentAuctionId = null;

            Console.WriteLine("🔌 New WebSocket connection established");

            try
            {
                while (webSocket.State == WebSocketState.Open)
                {
                    var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        Console.WriteLine($"📨 Received WebSocket message: {message}");
                        
                        var messageData = JsonSerializer.Deserialize<WebSocketMessage>(message);

                        if (messageData != null)
                        {
                            Console.WriteLine($"📋 Processing message type: {messageData.Type}, AuctionId: {messageData.AuctionId}");
                            
                            switch (messageData.Type)
                            {
                                case "subscribe":
                                    currentAuctionId = messageData.AuctionId;
                                    if (!string.IsNullOrEmpty(currentAuctionId))
                                    {
                                        SubscribeToAuction(webSocket, currentAuctionId);
                                    }
                                    break;
                                case "unsubscribe":
                                    if (!string.IsNullOrEmpty(currentAuctionId))
                                    {
                                        UnsubscribeFromAuction(webSocket, currentAuctionId);
                                    }
                                    break;
                            }
                        }
                    }
                    else if (result.MessageType == WebSocketMessageType.Close)
                    {
                        Console.WriteLine("🔌 WebSocket connection closed by client");
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ WebSocket error: {ex.Message}");
            }
            finally
            {
                Console.WriteLine("🔌 WebSocket connection cleanup");
                if (!string.IsNullOrEmpty(currentAuctionId))
                {
                    UnsubscribeFromAuction(webSocket, currentAuctionId);
                }
                _socketToAuction.TryRemove(webSocket, out _);
            }
        }

        private void SubscribeToAuction(WebSocket webSocket, string auctionId)
        {
            _auctionConnections.AddOrUpdate(
                auctionId,
                new HashSet<WebSocket> { webSocket },
                (key, existing) =>
                {
                    existing.Add(webSocket);
                    return existing;
                }
            );
            _socketToAuction[webSocket] = auctionId;
            Console.WriteLine($"✅ WebSocket subscribed to auction: {auctionId}");
            Console.WriteLine($"📊 Total connections for {auctionId}: {_auctionConnections[auctionId].Count}");
        }

        private void UnsubscribeFromAuction(WebSocket webSocket, string auctionId)
        {
            if (_auctionConnections.TryGetValue(auctionId, out var connections))
            {
                connections.Remove(webSocket);
                if (connections.Count == 0)
                {
                    _auctionConnections.TryRemove(auctionId, out _);
                }
            }
            Console.WriteLine($"WebSocket unsubscribed from auction {auctionId}");
        }

        public async Task BroadcastAuctionUpdateAsync(string auctionId, Auction auction)
        {
            if (_auctionConnections.TryGetValue(auctionId, out var connections))
            {
                var message = new
                {
                    type = "auction_update",
                    data = auction
                };
                var json = JsonSerializer.Serialize(message);
                var buffer = Encoding.UTF8.GetBytes(json);

                var tasks = connections.Where(ws => ws.State == WebSocketState.Open)
                    .Select(async ws =>
                    {
                        try
                        {
                            await ws.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Error sending auction update: {ex.Message}");
                        }
                    });

                await Task.WhenAll(tasks);
            }
        }

        public async Task BroadcastBidUpdateAsync(string auctionId, Bid bid)
        {
            if (_auctionConnections.TryGetValue(auctionId, out var connections))
            {
                var message = new
                {
                    type = "new_bid",
                    data = bid
                };
                var json = JsonSerializer.Serialize(message);
                var buffer = Encoding.UTF8.GetBytes(json);

                var tasks = connections.Where(ws => ws.State == WebSocketState.Open)
                    .Select(async ws =>
                    {
                        try
                        {
                            await ws.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Error sending bid update: {ex.Message}");
                        }
                    });

                await Task.WhenAll(tasks);
            }
        }

        public async Task BroadcastToAllAsync(object data, string messageType)
        {
            var allConnections = _auctionConnections.Values.SelectMany(x => x).Where(ws => ws.State == WebSocketState.Open).ToList();
            
            if (allConnections.Any())
            {
                var message = new
                {
                    type = messageType,
                    data = data
                };
                var json = JsonSerializer.Serialize(message);
                var buffer = Encoding.UTF8.GetBytes(json);

                var tasks = allConnections.Select(async ws =>
                {
                    try
                    {
                        await ws.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error broadcasting to all: {ex.Message}");
                    }
                });

                await Task.WhenAll(tasks);
            }
        }
    }

    public class WebSocketMessage
    {
        public string Type { get; set; } = string.Empty;
        public string? AuctionId { get; set; }
    }
}
