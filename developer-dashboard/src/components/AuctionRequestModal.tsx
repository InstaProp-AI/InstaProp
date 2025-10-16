import React, { useState } from 'react';
import { developerApi } from '../services/developerApi';

interface AuctionRequestModalProps {
  open: boolean;
  onClose: () => void;
  propertyId: number | null;
  onRequested: () => void;
}

const AuctionRequestModal: React.FC<AuctionRequestModalProps> = ({ open, onClose, propertyId, onRequested }) => {
  const [startPrice, setStartPrice] = useState(1000);
  const [startAt, setStartAt] = useState<string>(new Date().toISOString().slice(0, 16)); // local datetime input
  const [duration, setDuration] = useState(48); // hours
  const [buyNowPrice, setBuyNowPrice] = useState<number | undefined>(undefined);
  const [submitting, setSubmitting] = useState(false);

  if (!open || propertyId == null) return null;

  const onSubmit = async () => {
    setSubmitting(true);
    try {
      await developerApi.requestAuction({
        propertyId,
        startPrice,
        startAt: new Date(startAt).toISOString(),
        duration,
        buyNowPrice,
      });
      onRequested();
      onClose();
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-lg p-6">
        <h2 className="text-xl font-bold mb-4">Request Auction</h2>
        <div className="grid grid-cols-2 gap-3">
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Start Price" value={startPrice} onChange={(e) => setStartPrice(Number(e.target.value))} />
          <input type="datetime-local" className="border rounded-md px-3 py-2" value={startAt} onChange={(e) => setStartAt(e.target.value)} />
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Duration (hours)" value={duration} onChange={(e) => setDuration(Number(e.target.value))} />
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Buy Now Price (optional)" value={buyNowPrice ?? ''} onChange={(e) => setBuyNowPrice(e.target.value ? Number(e.target.value) : undefined)} />
        </div>
        <div className="mt-6 flex items-center justify-end gap-2">
          <button className="px-4 py-2 border rounded-md" onClick={onClose} disabled={submitting}>Cancel</button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-md" onClick={onSubmit} disabled={submitting}>{submitting ? 'Submitting...' : 'Submit Request'}</button>
        </div>
      </div>
    </div>
  );
};

export default AuctionRequestModal;


