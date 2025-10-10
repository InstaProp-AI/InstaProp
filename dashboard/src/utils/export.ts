// Export utility functions for CSV and Excel

export const exportToCSV = (data: any[], filename: string) => {
  if (!data || data.length === 0) {
    alert('No data to export');
    return;
  }

  // Get headers from first object
  const headers = Object.keys(data[0]);
  
  // Create CSV content
  const csvContent = [
    headers.join(','), // Header row
    ...data.map(row => 
      headers.map(header => {
        const value = row[header];
        // Handle values with commas or quotes
        if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        return value;
      }).join(',')
    )
  ].join('\n');

  // Create blob and download
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  
  link.setAttribute('href', url);
  link.setAttribute('download', `${filename}_${new Date().toISOString().split('T')[0]}.csv`);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

export const exportToExcel = (data: any[], filename: string) => {
  // For now, use CSV format (can be opened in Excel)
  // In future, can add xlsx library for true Excel format
  exportToCSV(data, filename);
};

export const exportUsersToCSV = (users: any[]) => {
  const exportData = users.map(user => ({
    ID: user.accountId,
    FirstName: user.firstName,
    LastName: user.lastName,
    Email: user.email,
    Phone: user.phoneNumber,
    Type: user.type,
    Status: user.status,
    EmailVerified: user.emailVerified ? 'Yes' : 'No',
    PhoneVerified: user.phoneVerified ? 'No' : 'No',
    JoinedDate: new Date(user.createdAt).toLocaleDateString()
  }));
  
  exportToCSV(exportData, 'users');
};

export const exportPropertiesToCSV = (properties: any[]) => {
  const exportData = properties.map(prop => ({
    ID: prop.propertyId,
    Name: prop.name,
    Location: prop.location,
    StartingPrice: prop.startingPrice,
    Bedrooms: prop.bedrooms,
    Bathrooms: prop.bathrooms,
    SquareFeet: prop.squareFeet,
    YearBuilt: prop.yearBuilt,
    Type: prop.type,
    Category: prop.category,
    Approved: prop.isApproved ? 'Yes' : 'No',
    CreatedDate: new Date(prop.createdAt).toLocaleDateString()
  }));
  
  exportToCSV(exportData, 'properties');
};

export const exportBidsToCSV = (bids: any[]) => {
  const exportData = bids.map(bid => ({
    BidID: bid.bidId,
    BidderName: bid.bidderName,
    BidderEmail: bid.bidderEmail,
    Property: bid.propertyName,
    Location: bid.propertyLocation,
    BidAmount: bid.bidAmount,
    PreviousBid: bid.previousBid,
    Increase: bid.bidAmount - bid.previousBid,
    Status: bid.status,
    Timestamp: new Date(bid.timestamp).toLocaleString()
  }));
  
  exportToCSV(exportData, 'bids');
};

export const exportAuctionsToCSV = (auctions: any[]) => {
  const exportData = auctions.map(auction => ({
    AuctionID: auction.auctionId,
    Property: auction.propertyName,
    Location: auction.location,
    StartingPrice: auction.startingPrice,
    CurrentBid: auction.currentBid,
    BidCount: auction.bidCount,
    Status: auction.status,
    HighestBidder: auction.highestBidder || 'N/A',
    StartTime: new Date(auction.startTime).toLocaleString(),
    EndTime: new Date(auction.endTime).toLocaleString()
  }));
  
  exportToCSV(exportData, 'auctions');
};


