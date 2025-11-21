import React, { useState, useEffect } from 'react';
import { valuationApi, propertiesApi, authApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Calculator, TrendingUp, DollarSign, Calendar, Home } from 'lucide-react';

const ValuationPage: React.FC = () => {
  const toast = useToast();
  const [valuations, setValuations] = useState<any[]>([]);
  const [properties, setProperties] = useState<any[]>([]);
  const [selectedPropertyId, setSelectedPropertyId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [calculating, setCalculating] = useState(false);

  useEffect(() => {
    fetchProperties();
    fetchValuationHistory();
  }, []);

  const fetchProperties = async () => {
    try {
      // Get user role to determine which endpoint to use
      const currentUser = await authApi.getCurrentAccount();
      // Check roleName first (from backend), then roleId, then legacy type
      const isAdmin = currentUser.roleName === 'Admin' || currentUser.roleId === 9823749823749823 || currentUser.type === 'Admin';
      const isDeveloper = currentUser.roleName === 'Developer' || currentUser.roleId === 7823647823647823 || currentUser.type === 'Developer';
      const userRole = isAdmin ? 'Admin' : (isDeveloper ? 'Developer' : null);
      
      // Get properties - handle both paginated (Admin) and non-paginated (Developer) responses
      const response = await propertiesApi.getProperties(userRole || undefined);
      const propertiesData = userRole === 'Admin' && 'data' in response 
        ? (response as any).data || []
        : (response as any[]) || [];
      
      setProperties(propertiesData);
    } catch (error: any) {
      console.error('Error fetching properties:', error);
      toast.error(error?.response?.data?.message || 'Failed to load properties');
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

  const handleCalculateValuation = async (propertyId: number) => {
    try {
      setCalculating(true);
      const property = properties.find(p => p.propertyId === propertyId);
      if (!property) {
        toast.error('Property not found');
        return;
      }

      const result = await valuationApi.calculate({
        propertyId,
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
        squareFeet: property.squareFeet,
        location: property.location,
        type: property.type
      });

      toast.success(`Property valuation: $${result.estimatedValue?.toLocaleString() || 'N/A'}`);
      fetchValuationHistory();
    } catch (error: any) {
      console.error('Error calculating valuation:', error);
      toast.error(error?.response?.data?.message || 'Failed to calculate valuation');
    } finally {
      setCalculating(false);
    }
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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Property Valuation</h1>
        <p className="text-gray-600">Calculate and track property valuations</p>
      </div>

      <div className="mb-6 bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4">Calculate Valuation</h2>
        <div className="flex gap-4">
          <select
            value={selectedPropertyId || ''}
            onChange={(e) => setSelectedPropertyId(Number(e.target.value))}
            className="flex-1 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">Select a property</option>
            {properties.map((property) => (
              <option key={property.propertyId} value={property.propertyId}>
                {property.name} - {property.location}
              </option>
            ))}
          </select>
          <button
            onClick={() => selectedPropertyId && handleCalculateValuation(selectedPropertyId)}
            disabled={!selectedPropertyId || calculating}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center gap-2"
          >
            <Calculator className="h-5 w-5" />
            {calculating ? 'Calculating...' : 'Calculate'}
          </button>
        </div>
      </div>

      {valuations.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <Calculator className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No valuations found</h3>
          <p className="text-gray-600">Property valuations will appear here once calculated.</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold">Valuation History</h2>
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
                  <tr key={valuation.valuationId || valuation.id} className="hover:bg-gray-50">
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
                          {valuation.estimatedValue?.toLocaleString() || valuation.value?.toLocaleString() || 'N/A'}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-500">{valuation.method || valuation.valuationMethod || 'Standard'}</span>
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
    </div>
  );
};

export default ValuationPage;

