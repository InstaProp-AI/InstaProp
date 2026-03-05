import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import {
  ToggleLeft,
  ToggleRight,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Info,
} from 'lucide-react';

interface FeatureFlag {
  featureFlagId: string;
  featureKey: string;
  isEnabled: boolean;
  description: string;
  lastUpdatedAt: string;
  updatedByAdminId: string | null;
}

const PHASE_LABELS: Record<string, 'MVP' | 'Phase 2'> = {
  FeedExplore: 'MVP',
  PaymentScheduleScanner: 'MVP',
  Redemptions: 'MVP',
  Valuation: 'MVP',
  News: 'Phase 2',
  LiveStreaming: 'Phase 2',
  AIBroker: 'Phase 2',
  Leaderboard: 'Phase 2',
  GoldPriceComparison: 'Phase 2',
  SalesTeams: 'Phase 2',
};

const FeatureFlagsPage: React.FC = () => {
  const toast = useToast();
  const [flags, setFlags] = useState<FeatureFlag[]>([]);
  const [loading, setLoading] = useState(true);
  const [togglingKey, setTogglingKey] = useState<string | null>(null);

  const fetchFlags = useCallback(async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/flags');
      setFlags(response.data?.data ?? response.data ?? []);
    } catch (err) {
      toast.error('Failed to load feature flags.');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchFlags();
  }, [fetchFlags]);

  const handleToggle = async (flag: FeatureFlag) => {
    if (togglingKey === flag.featureKey) return;
    setTogglingKey(flag.featureKey);
    try {
      await api.put(`/admin/flags/${flag.featureKey}`, { isEnabled: !flag.isEnabled });
      setFlags(prev =>
        prev.map(f =>
          f.featureKey === flag.featureKey
            ? { ...f, isEnabled: !f.isEnabled, lastUpdatedAt: new Date().toISOString() }
            : f
        )
      );
      toast.success(`'${flag.featureKey}' is now ${!flag.isEnabled ? 'enabled' : 'disabled'}.`);
    } catch {
      toast.error(`Failed to toggle '${flag.featureKey}'.`);
    } finally {
      setTogglingKey(null);
    }
  };

  const mvpFlags = flags.filter(f => PHASE_LABELS[f.featureKey] === 'MVP');
  const phase2Flags = flags.filter(f => PHASE_LABELS[f.featureKey] === 'Phase 2');
  const unknownFlags = flags.filter(f => !PHASE_LABELS[f.featureKey]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <RefreshCw className="animate-spin text-blue-500" size={32} />
      </div>
    );
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Feature Flags</h1>
          <p className="text-sm text-gray-500 mt-1">
            Toggle features on or off across the Instaprop mobile app. Changes take effect within 5 minutes (cache TTL).
          </p>
        </div>
        <button
          onClick={fetchFlags}
          className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
        >
          <RefreshCw size={16} />
          Refresh
        </button>
      </div>

      {/* Info banner */}
      <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg flex items-start gap-3">
        <Info size={18} className="text-blue-500 mt-0.5 flex-shrink-0" />
        <div className="text-sm text-blue-700">
          <strong>UI-Gate Only:</strong> Flags hide navigation items in the Flutter app — backend endpoints remain fully active.
          Backbone features (Auctions, Bidding, KYC, Chat, Notifications) are never flagged and cannot be toggled off.
        </div>
      </div>

      <FlagGroup title="MVP Features" subtitle="Enabled by default at launch" flags={mvpFlags} onToggle={handleToggle} togglingKey={togglingKey} />
      <FlagGroup title="Phase 2 Features" subtitle="Disabled by default — enable when ready" flags={phase2Flags} onToggle={handleToggle} togglingKey={togglingKey} />
      {unknownFlags.length > 0 && (
        <FlagGroup title="Other Flags" subtitle="Custom flags" flags={unknownFlags} onToggle={handleToggle} togglingKey={togglingKey} />
      )}
    </div>
  );
};

interface FlagGroupProps {
  title: string;
  subtitle: string;
  flags: FeatureFlag[];
  onToggle: (flag: FeatureFlag) => void;
  togglingKey: string | null;
}

const FlagGroup: React.FC<FlagGroupProps> = ({ title, subtitle, flags, onToggle, togglingKey }) => {
  if (flags.length === 0) return null;

  return (
    <div className="mb-8">
      <div className="mb-3">
        <h2 className="text-lg font-semibold text-gray-800">{title}</h2>
        <p className="text-xs text-gray-500">{subtitle}</p>
      </div>
      <div className="bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm">
        {flags.map((flag, index) => (
          <FlagRow
            key={flag.featureKey}
            flag={flag}
            onToggle={onToggle}
            isToggling={togglingKey === flag.featureKey}
            isLast={index === flags.length - 1}
          />
        ))}
      </div>
    </div>
  );
};

interface FlagRowProps {
  flag: FeatureFlag;
  onToggle: (flag: FeatureFlag) => void;
  isToggling: boolean;
  isLast: boolean;
}

const FlagRow: React.FC<FlagRowProps> = ({ flag, onToggle, isToggling, isLast }) => {
  const updatedAt = flag.lastUpdatedAt
    ? new Date(flag.lastUpdatedAt).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      })
    : '—';

  return (
    <div
      className={`flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors ${!isLast ? 'border-b border-gray-100' : ''}`}
    >
      <div className="flex-1 min-w-0 mr-4">
        <div className="flex items-center gap-2 mb-0.5">
          <span className="font-semibold text-gray-800 text-sm">{flag.featureKey}</span>
          {flag.isEnabled ? (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">
              <CheckCircle size={10} /> Enabled
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-500">
              <AlertCircle size={10} /> Disabled
            </span>
          )}
        </div>
        <p className="text-xs text-gray-500 truncate">{flag.description}</p>
        <p className="text-xs text-gray-400 mt-0.5">Last updated: {updatedAt}</p>
      </div>
      <button
        onClick={() => onToggle(flag)}
        disabled={isToggling}
        className={`flex-shrink-0 p-1 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-blue-500 ${
          flag.isEnabled ? 'text-green-500 hover:text-green-600' : 'text-gray-400 hover:text-gray-500'
        }`}
        aria-label={`Toggle ${flag.featureKey}`}
      >
        {isToggling ? (
          <RefreshCw size={28} className="animate-spin" />
        ) : flag.isEnabled ? (
          <ToggleRight size={32} />
        ) : (
          <ToggleLeft size={32} />
        )}
      </button>
    </div>
  );
};

export default FeatureFlagsPage;
