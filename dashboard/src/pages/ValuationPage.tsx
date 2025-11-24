import React, { useState, useEffect } from 'react';
import { valuationApi, propertiesApi, authApi, propertyFinancialsApi, parentPropertyApi, goldApi, priceHistoryApi, salesApi, projectsApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Calculator, TrendingUp, DollarSign, Calendar, Home, BarChart3, PieChart, Target, Award, AlertCircle, Sparkles, Coins, Building2, Users, ArrowUpRight, ArrowDownRight, ChevronRight } from 'lucide-react';
import { ROLE_IDS, Account } from '../types';

const ValuationPage: React.FC = () => {
  const toast = useToast();
  const [valuations, setValuations] = useState<any[]>([]);
  
  // Current user state
  const [currentUser, setCurrentUser] = useState<Account | null>(null);
  const [isDeveloper, setIsDeveloper] = useState(false);
  
  // Step-by-step selection state
  const [developers, setDevelopers] = useState<any[]>([]);
  const [selectedDeveloperId, setSelectedDeveloperId] = useState<string | null>(null);
  const [projects, setProjects] = useState<any[]>([]);
  const [selectedProjectId, setSelectedProjectId] = useState<string | null>(null);
  const [properties, setProperties] = useState<any[]>([]);
  const [selectedPropertyId, setSelectedPropertyId] = useState<string | null>(null);
  
  const [selectedProperty, setSelectedProperty] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [loadingDevelopers, setLoadingDevelopers] = useState(false);
  const [loadingProjects, setLoadingProjects] = useState(false);
  const [loadingProperties, setLoadingProperties] = useState(false);
  const [calculating, setCalculating] = useState(false);
  const [analysisData, setAnalysisData] = useState<any>(null);
  const [loadingAnalysis, setLoadingAnalysis] = useState(false);

  useEffect(() => {
    const initializePage = async () => {
      try {
        setLoading(true);
        const user = await authApi.getCurrentAccount();
        setCurrentUser(user);
        
        // Check if user is a developer
        const userIsDeveloper = user.roleId === ROLE_IDS.DEVELOPER || 
                                user.roleName === 'Developer' || 
                                user.type === 'Developer';
        setIsDeveloper(userIsDeveloper);
        
        // If developer, automatically set their developer ID
        if (userIsDeveloper) {
          setSelectedDeveloperId(user.accountId);
        } else {
          // If admin, fetch all developers for selection
          await fetchDevelopers();
        }
        
        await fetchValuationHistory();
      } catch (error: any) {
        console.error('Error initializing page:', error);
        toast.error('Failed to load page data');
      } finally {
        setLoading(false);
      }
    };
    
    initializePage();
  }, []);

  useEffect(() => {
    if (selectedDeveloperId) {
      fetchProjects(String(selectedDeveloperId));
    } else {
      setProjects([]);
      setSelectedProjectId(null);
      setProperties([]);
      setSelectedPropertyId(null);
    }
  }, [selectedDeveloperId]);

  useEffect(() => {
    if (selectedProjectId) {
      fetchPropertiesForProject(String(selectedProjectId));
    } else {
      setProperties([]);
      setSelectedPropertyId(null);
    }
  }, [selectedProjectId]);

  useEffect(() => {
    if (selectedPropertyId) {
      // Don't auto-fetch analysis, wait for user to click analyze
      setAnalysisData(null);
    }
  }, [selectedPropertyId]);

  const fetchDevelopers = async () => {
    try {
      setLoadingDevelopers(true);
      const devs = await salesApi.getDevelopers();
      setDevelopers(devs);
    } catch (error: any) {
      console.error('Error fetching developers:', error);
      toast.error(error?.response?.data?.message || 'Failed to load developers');
    } finally {
      setLoadingDevelopers(false);
      setLoading(false);
    }
  };

  const fetchProjects = async (developerId: string) => {
    try {
      setLoadingProjects(true);
      setSelectedProjectId(null);
      setProperties([]);
      setSelectedPropertyId(null);
      const projs = await projectsApi.getProjectsByDeveloper(developerId);
      setProjects(projs);
    } catch (error: any) {
      console.error('Error fetching projects:', error);
      toast.error(error?.response?.data?.message || 'Failed to load projects');
    } finally {
      setLoadingProjects(false);
    }
  };

  const fetchPropertiesForProject = async (projectId: string) => {
    try {
      setLoadingProperties(true);
      setSelectedPropertyId(null);
      const props = await projectsApi.getProjectProperties(projectId);
      setProperties(props);
    } catch (error: any) {
      console.error('Error fetching properties:', error);
      toast.error(error?.response?.data?.message || 'Failed to load properties');
    } finally {
      setLoadingProperties(false);
    }
  };

  const fetchValuationHistory = async () => {
    try {
      setLoading(true);
      const data = await valuationApi.getValuationHistory();
      setValuations(data || []);
    } catch (error: any) {
      console.error('Error fetching valuation history:', error);
      toast.error(error?.response?.data?.message || 'Failed to load valuation history');
    } finally {
      setLoading(false);
    }
  };

  const fetchPropertyAnalysis = async (propertyId: string) => {
    try {
      setLoadingAnalysis(true);
      // Get property from local state or fetch it
      let property = properties.find(p => p.propertyId === propertyId || p.PropertyId === propertyId);
      if (!property) {
        // Fetch property details if not in local state
        try {
          property = await propertiesApi.getProperty(propertyId);
        } catch (error) {
          toast.error('Property not found');
          return;
        }
      }

      setSelectedProperty(property);

      // Get parentPropertyId (handle both camelCase and PascalCase)
      const parentPropertyId = property.parentPropertyId || property.ParentPropertyId;
      const buyingPrice = property.buyingPrice || property.BuyingPrice;

      // Fetch all analysis data in parallel
      const [
        basicValuation,
        aiValuation,
        financials,
        priceHistory,
        parentProperty,
        siblingProperties,
        goldComparison
      ] = await Promise.allSettled([
        valuationApi.calculate({
          propertyId,
          bedrooms: property.bedrooms || property.Bedrooms,
          bathrooms: property.bathrooms || property.Bathrooms,
          squareFeet: property.squareFeet || property.SquareFeet,
          location: property.location || property.Location,
          type: property.type || property.Type
        }),
        valuationApi.calculateAI({
          propertyId,
          bedrooms: property.bedrooms || property.Bedrooms,
          bathrooms: property.bathrooms || property.Bathrooms,
          squareFeet: property.squareFeet || property.SquareFeet,
          location: property.location || property.Location,
          type: property.type || property.Type,
          yearBuilt: property.yearBuilt || property.YearBuilt,
          propertyType: property.type || property.Type
        }),
        propertyFinancialsApi.getPropertyFinancials(propertyId).catch(() => null),
        parentPropertyId ? priceHistoryApi.getPriceHistoryForParentProperty(parentPropertyId).catch(() => null) : Promise.resolve(null),
        parentPropertyId ? parentPropertyApi.getParentProperty(parentPropertyId).catch(() => null) : Promise.resolve(null),
        parentPropertyId ? parentPropertyApi.getParentChildren(parentPropertyId).catch(() => null) : Promise.resolve(null),
        parentPropertyId ? goldApi.compareWithProperty(parentPropertyId, buyingPrice).catch(() => null) : Promise.resolve(null)
      ]);

      setAnalysisData({
        basicValuation: basicValuation.status === 'fulfilled' ? basicValuation.value : null,
        aiValuation: aiValuation.status === 'fulfilled' ? aiValuation.value : null,
        financials: financials.status === 'fulfilled' ? financials.value : null,
        priceHistory: priceHistory.status === 'fulfilled' ? priceHistory.value : null,
        parentProperty: parentProperty.status === 'fulfilled' ? parentProperty.value : null,
        siblingProperties: siblingProperties.status === 'fulfilled' ? siblingProperties.value : null,
        goldComparison: goldComparison.status === 'fulfilled' ? goldComparison.value : null
      });
    } catch (error: any) {
      console.error('Error fetching property analysis:', error);
      toast.error('Failed to load property analysis');
    } finally {
      setLoadingAnalysis(false);
    }
  };

  const handleCalculateValuation = async (propertyId: string) => {
    await fetchPropertyAnalysis(propertyId);
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Property Valuation & Analysis</h1>
        <p className="text-gray-600">Comprehensive property analysis with ROI, market trends, and investment comparisons</p>
      </div>

      {/* Step-by-Step Property Selection */}
      <div className="mb-6 bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <Home className="h-5 w-5" />
          Select Property for Analysis
        </h2>
        
        <div className="space-y-4">
          {/* Step 1: Select Developer (Only for Admins) */}
          {!isDeveloper && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Step 1: Select Developer
              </label>
              <select
                value={selectedDeveloperId || ''}
                onChange={(e) => setSelectedDeveloperId(e.target.value || null)}
                disabled={loadingDevelopers}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100"
              >
                <option value="">{loadingDevelopers ? 'Loading developers...' : 'Select a developer'}</option>
                {developers.map((developer) => (
                  <option key={developer.accountId} value={developer.accountId}>
                    {developer.firstName} {developer.lastName} {developer.email ? `(${developer.email})` : ''}
                  </option>
                ))}
              </select>
            </div>
          )}
          
          {/* Developer Info (Only for Developers) */}
          {isDeveloper && currentUser && (
            <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
              <p className="text-sm font-medium text-blue-900">
                Analyzing properties for: <span className="font-semibold">{currentUser.firstName} {currentUser.lastName}</span>
              </p>
            </div>
          )}

          {/* Step 2: Select Project */}
          {selectedDeveloperId && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                <ChevronRight className="h-4 w-4 text-gray-400" />
                {isDeveloper ? 'Step 1: Select Project' : 'Step 2: Select Project'}
              </label>
              <select
                value={selectedProjectId || ''}
                onChange={(e) => setSelectedProjectId(e.target.value || null)}
                disabled={loadingProjects}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100"
              >
                <option value="">{loadingProjects ? 'Loading projects...' : 'Select a project'}</option>
                {projects.map((project) => (
                  <option key={project.projectId} value={project.projectId}>
                    {project.name} - {project.location} ({project.propertiesCount || 0} units)
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Step 3: Select Unit/Property */}
          {selectedProjectId && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                <ChevronRight className="h-4 w-4 text-gray-400" />
                {isDeveloper ? 'Step 2: Select Unit' : 'Step 3: Select Unit'}
              </label>
              <select
                value={selectedPropertyId || ''}
                onChange={(e) => setSelectedPropertyId(e.target.value || null)}
                disabled={loadingProperties}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100"
              >
                <option value="">{loadingProperties ? 'Loading properties...' : 'Select a unit'}</option>
                {properties.map((property) => (
                  <option key={property.propertyId} value={property.propertyId}>
                    {property.name || `Unit ${property.unitNumber || property.propertyId}`} - {property.location || 'N/A'}
                    {property.buyingPrice ? ` ($${property.buyingPrice.toLocaleString()})` : ''}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Analyze Button */}
          {selectedPropertyId && (
            <div className="pt-2">
              <button
                onClick={() => selectedPropertyId && handleCalculateValuation(selectedPropertyId)}
                disabled={calculating || loadingAnalysis || !selectedPropertyId}
                className="w-full px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center gap-2 font-semibold"
              >
                <Calculator className="h-5 w-5" />
                {loadingAnalysis ? 'Analyzing...' : calculating ? 'Calculating...' : 'Analyze Property'}
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Comprehensive Analysis Display */}
      {loadingAnalysis && (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Loading comprehensive analysis...</p>
        </div>
      )}

      {analysisData && selectedProperty && !loadingAnalysis && (
        <div className="space-y-6">
          {/* Property Overview */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Home className="h-6 w-6 text-blue-600" />
              Property Overview
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p className="text-sm text-gray-500">Property Name</p>
                <p className="font-semibold">{selectedProperty.name || selectedProperty.Name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Location</p>
                <p className="font-semibold">{selectedProperty.location || selectedProperty.Location}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Size</p>
                <p className="font-semibold">{(selectedProperty.squareFeet || selectedProperty.SquareFeet)?.toLocaleString()} sq ft</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Bedrooms / Bathrooms</p>
                <p className="font-semibold">{selectedProperty.bedrooms || selectedProperty.Bedrooms} / {selectedProperty.bathrooms || selectedProperty.Bathrooms}</p>
              </div>
            </div>
          </div>

          {/* Valuation Results */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Basic Valuation */}
            {analysisData.basicValuation && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                  <Calculator className="h-5 w-5 text-blue-600" />
                  Basic Valuation
                </h3>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Estimated Value</span>
                    <span className="text-2xl font-bold text-green-600">
                      ${analysisData.basicValuation.estimatedValue?.toLocaleString() || 'N/A'}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Base Price</span>
                    <span className="font-semibold">${analysisData.basicValuation.basePrice?.toLocaleString() || 'N/A'}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Location Multiplier</span>
                    <span className="font-semibold">{(analysisData.basicValuation.locationMultiplier || 1).toFixed(2)}x</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Year Factor</span>
                    <span className="font-semibold">{(analysisData.basicValuation.yearFactor || 1).toFixed(2)}x</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Confidence</span>
                    <span className="font-semibold">{(analysisData.basicValuation.confidence * 100 || 0).toFixed(0)}%</span>
                  </div>
                </div>
              </div>
            )}

            {/* AI-Enhanced Valuation */}
            {analysisData.aiValuation && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                  <Sparkles className="h-5 w-5 text-purple-600" />
                  AI-Enhanced Valuation
                </h3>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">AI Estimated Value</span>
                    <span className="text-2xl font-bold text-purple-600">
                      ${analysisData.aiValuation.estimatedValue?.toLocaleString() || 'N/A'}
                    </span>
                  </div>
                  <div className="bg-gray-50 p-3 rounded">
                    <p className="text-sm text-gray-600 mb-1">Price Range</p>
                    <p className="font-semibold">
                      ${analysisData.aiValuation.priceRangeLow?.toLocaleString() || 'N/A'} - ${analysisData.aiValuation.priceRangeHigh?.toLocaleString() || 'N/A'}
                    </p>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Confidence</span>
                    <span className="font-semibold">{(analysisData.aiValuation.confidence * 100 || 0).toFixed(0)}%</span>
                  </div>
                  {analysisData.aiValuation.aiReasoning && (
                    <div className="bg-blue-50 p-3 rounded mt-3">
                      <p className="text-sm font-semibold mb-1">AI Reasoning</p>
                      <p className="text-sm text-gray-700">{analysisData.aiValuation.aiReasoning}</p>
                    </div>
                  )}
                  {analysisData.aiValuation.marketTrends && (
                    <div className="bg-green-50 p-3 rounded mt-3">
                      <p className="text-sm font-semibold mb-1">Market Trends</p>
                      <p className="text-sm text-gray-700">{analysisData.aiValuation.marketTrends}</p>
                    </div>
                  )}
                  {analysisData.aiValuation.topComparables && analysisData.aiValuation.topComparables.length > 0 && (
                    <div className="mt-3">
                      <p className="text-sm font-semibold mb-2">Top Comparable Properties ({analysisData.aiValuation.topComparables.length})</p>
                      <div className="space-y-2 max-h-40 overflow-y-auto">
                        {analysisData.aiValuation.topComparables.slice(0, 3).map((comp: any, idx: number) => (
                          <div key={idx} className="bg-gray-50 p-2 rounded text-sm">
                            <p className="font-semibold">{comp.name}</p>
                            <p className="text-gray-600">{comp.location} - ${comp.price?.toLocaleString()}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Financial Analysis */}
          {analysisData.financials && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                <PieChart className="h-5 w-5 text-green-600" />
                Financial Analysis
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-blue-50 p-4 rounded">
                  <p className="text-sm text-gray-600 mb-1">Buying Price</p>
                  <p className="text-xl font-bold text-blue-600">
                    ${analysisData.financials.buyingPrice?.toLocaleString() || analysisData.financials.contractedPrice?.toLocaleString() || 'N/A'}
                  </p>
                </div>
                <div className="bg-green-50 p-4 rounded">
                  <p className="text-sm text-gray-600 mb-1">Market Value</p>
                  <p className="text-xl font-bold text-green-600">
                    ${analysisData.financials.marketValue?.toLocaleString() || 'N/A'}
                  </p>
                </div>
                <div className="bg-purple-50 p-4 rounded">
                  <p className="text-sm text-gray-600 mb-1">ROI</p>
                  <p className={`text-xl font-bold ${(analysisData.financials.roiPercent || 0) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {analysisData.financials.roiPercent ? `${analysisData.financials.roiPercent.toFixed(2)}%` : 'N/A'}
                  </p>
                </div>
                <div className="bg-orange-50 p-4 rounded">
                  <p className="text-sm text-gray-600 mb-1">Paid So Far</p>
                  <p className="text-xl font-bold text-orange-600">
                    ${analysisData.financials.paidSoFar?.toLocaleString() || '0'}
                  </p>
                </div>
                {analysisData.financials.remainingToPay && (
                  <div className="bg-red-50 p-4 rounded">
                    <p className="text-sm text-gray-600 mb-1">Remaining to Pay</p>
                    <p className="text-xl font-bold text-red-600">
                      ${analysisData.financials.remainingToPay.toLocaleString()}
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Gold Comparison */}
          {analysisData.goldComparison && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                <Coins className="h-5 w-5 text-yellow-600" />
                Gold Investment Comparison
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <p className="text-sm text-gray-600 mb-2">Property Value in Gold</p>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span>Grams:</span>
                      <span className="font-semibold">{analysisData.goldComparison.Comparison?.PropertyValueInGold?.Grams?.toLocaleString() || 'N/A'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Ounces:</span>
                      <span className="font-semibold">{analysisData.goldComparison.Comparison?.PropertyValueInGold?.Ounces?.toLocaleString() || 'N/A'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Kilograms:</span>
                      <span className="font-semibold">{analysisData.goldComparison.Comparison?.PropertyValueInGold?.Kilograms?.toLocaleString() || 'N/A'}</span>
                    </div>
                  </div>
                </div>
                <div>
                  <p className="text-sm text-gray-600 mb-2">Gold Price Trend</p>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span>Price Change:</span>
                      <span className={`font-semibold ${(analysisData.goldComparison.Comparison?.GoldPriceChangePercent || 0) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                        {analysisData.goldComparison.Comparison?.GoldPriceChangePercent?.toFixed(2) || '0'}%
                      </span>
                    </div>
                    <div className="bg-yellow-50 p-3 rounded mt-3">
                      <p className="text-sm font-semibold mb-1">Recommendation</p>
                      <p className="text-sm text-gray-700">{analysisData.goldComparison.Comparison?.Recommendation || 'N/A'}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Sibling Properties Analysis */}
          {analysisData.siblingProperties && Array.isArray(analysisData.siblingProperties) && analysisData.siblingProperties.length > 0 && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                <Building2 className="h-5 w-5 text-indigo-600" />
                Sibling Properties Analysis ({analysisData.siblingProperties.length} units)
              </h3>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Unit</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Price</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Size</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {analysisData.siblingProperties.slice(0, 10).map((sibling: any, idx: number) => (
                      <tr key={idx} className="hover:bg-gray-50">
                        <td className="px-4 py-3 whitespace-nowrap text-sm">{sibling.unitNumber || `Unit ${idx + 1}`}</td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm font-semibold">
                          ${sibling.buyingPrice?.toLocaleString() || 'N/A'}
                        </td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm">{sibling.squareFeet?.toLocaleString() || 'N/A'} sq ft</td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm">
                          <span className={`px-2 py-1 rounded text-xs ${sibling.ownerId ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                            {sibling.ownerId ? 'Sold' : 'Available'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {analysisData.siblingProperties.length > 10 && (
                <p className="text-sm text-gray-500 mt-2">Showing 10 of {analysisData.siblingProperties.length} units</p>
              )}
            </div>
          )}

          {/* Parent Property Details */}
          {analysisData.parentProperty && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                <Building2 className="h-5 w-5 text-blue-600" />
                Parent Property Details
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <p className="text-sm text-gray-600">Project</p>
                  <p className="font-semibold">{analysisData.parentProperty.projectName || analysisData.parentProperty.Project?.name || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Type</p>
                  <p className="font-semibold">{analysisData.parentProperty.type || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Area</p>
                  <p className="font-semibold">{analysisData.parentProperty.areaSqm || 'N/A'} sqm</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Finishing</p>
                  <p className="font-semibold">{analysisData.parentProperty.finishingType || 'N/A'}</p>
                </div>
              </div>
            </div>
          )}

          {/* Price History */}
          {analysisData.priceHistory && Array.isArray(analysisData.priceHistory) && analysisData.priceHistory.length > 0 && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                <BarChart3 className="h-5 w-5 text-green-600" />
                Price History & Trends
              </h3>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Price</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Change</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {analysisData.priceHistory.slice(0, 10).map((history: any, idx: number) => (
                      <tr key={idx} className="hover:bg-gray-50">
                        <td className="px-4 py-3 whitespace-nowrap text-sm">
                          {new Date(history.priceDate || history.date).toLocaleDateString()}
                        </td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm font-semibold">
                          ${history.price?.toLocaleString() || history.value?.toLocaleString() || 'N/A'}
                        </td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm">
                          {idx > 0 && (
                            <span className={`flex items-center gap-1 ${(history.price || history.value) > (analysisData.priceHistory[idx - 1].price || analysisData.priceHistory[idx - 1].value) ? 'text-green-600' : 'text-red-600'}`}>
                              {(history.price || history.value) > (analysisData.priceHistory[idx - 1].price || analysisData.priceHistory[idx - 1].value) ? (
                                <ArrowUpRight className="h-4 w-4" />
                              ) : (
                                <ArrowDownRight className="h-4 w-4" />
                              )}
                              {((((history.price || history.value) - (analysisData.priceHistory[idx - 1].price || analysisData.priceHistory[idx - 1].value)) / (analysisData.priceHistory[idx - 1].price || analysisData.priceHistory[idx - 1].value)) * 100).toFixed(2)}%
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Valuation History Table */}
      {!selectedPropertyId && (
        <>
          {valuations.length === 0 ? (
            <div className="text-center py-12 bg-white rounded-lg shadow">
              <Calculator className="mx-auto h-12 w-12 text-gray-400 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No valuations found</h3>
              <p className="text-gray-600">Select a property above to perform comprehensive analysis.</p>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow overflow-hidden">
              <div className="px-6 py-4 border-b border-gray-200">
                <h2 className="text-lg font-semibold">Recent Valuations</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Property</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estimated Value</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Method</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {valuations.map((valuation) => (
                      <tr key={valuation.propertyId || valuation.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <Home className="h-4 w-4 text-gray-400" />
                            <span className="text-sm font-medium text-gray-900">
                              {valuation.propertyName || 'Unknown Property'}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <DollarSign className="h-4 w-4 text-green-500" />
                            <span className="text-sm font-semibold text-gray-900">
                              ${valuation.calculatedValue?.toLocaleString() || valuation.value?.toLocaleString() || 'N/A'}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className="text-sm text-gray-500">Standard</span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <Calendar className="h-4 w-4 text-gray-400" />
                            <span className="text-sm text-gray-900">
                              {new Date(valuation.calculatedAt || valuation.createdAt).toLocaleDateString()}
                            </span>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default ValuationPage;
