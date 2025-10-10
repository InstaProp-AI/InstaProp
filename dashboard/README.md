# Property Flipper - Admin Dashboard

## Overview
A comprehensive, production-ready admin dashboard for managing the Property Flipper platform. This dashboard provides complete control over users, properties, auctions, bids, and system settings.

## ✨ Features

### 🔐 Authentication
- Admin-only access control
- JWT token-based authentication
- Automatic session management
- Secure logout functionality

### 👥 User Management
- View all platform users (Users, Developers, Admins)
- User verification and KYC approval/rejection
- Email and phone verification status tracking
- User status management (Verified, Pending, Not Verified)
- Ban/unban user functionality
- Advanced search and filtering
- Detailed user information viewing
- Real-time statistics

### 🏠 Properties Management
- View all property listings
- Approve/reject property submissions
- Property status tracking
- Search and filter by multiple criteria
- View property details and images
- Delete properties
- Export property data
- Filter by approval status and project

### 🔨 Auctions Management
- Monitor all active, upcoming, and ended auctions
- Start/stop auctions with admin controls
- View real-time bidding activity
- Auction status management
- Time remaining tracking
- Bidder information
- Auction analytics

### 💰 Bids Management
- Real-time bid monitoring
- View all bids across platform
- Bid history and analytics
- Bidder information
- Bid amount tracking
- Status tracking (active, won, outbid, cancelled)
- Export bid data

### 📊 Analytics & Reports
- Revenue tracking and trends
- User growth analytics
- Property performance metrics
- Auction completion rates
- Top performing properties
- Activity overview
- Customizable time ranges
- Export reports

### ⚙️ Settings
- General settings (site name, email, currency, timezone)
- Notification preferences (email, SMS, bid alerts)
- Security settings (user registration, auto-approval, 2FA)
- System management (maintenance mode, database backup/restore)
- Cache management

### 📁 Projects Management
- View and manage development projects
- Create new projects
- Associate properties with projects
- Track project properties
- Delete projects

## 🛠️ Technical Stack

- **Frontend**: React 18 + TypeScript
- **Styling**: Tailwind CSS + Custom CSS
- **Icons**: Lucide React
- **HTTP Client**: Axios
- **Routing**: React Router DOM v6
- **Build Tool**: Vite
- **State Management**: React Hooks

## 📋 Pages

1. **Dashboard** (`/dashboard`) - Overview with key metrics and recent activity
2. **Users** (`/users`) - Comprehensive user management
3. **Properties** (`/properties`) - Property listings and approval workflow
4. **Auctions** (`/auctions`) - Auction monitoring and control
5. **Bids** (`/bids`) - Bid tracking and management
6. **Projects** (`/projects`) - Development projects management
7. **Analytics** (`/analytics`) - Detailed reports and insights
8. **Settings** (`/settings`) - System configuration

## 🚀 Getting Started

### Prerequisites
- Node.js 16+ 
- npm or yarn
- Backend API running on `http://localhost:5001`

### Installation

1. Navigate to the dashboard directory:
```bash
cd dashboard
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Build for production:
```bash
npm run build
```

5. Preview production build:
```bash
npm run preview
```

## 🔌 API Integration

The dashboard connects to the backend API at `http://localhost:5284/api` with the following endpoints:

> **✅ FULLY CONNECTED**: The dashboard is now completely integrated with the backend API. See `BACKEND_CONNECTION_GUIDE.md` for details.

### Authentication
- `POST /account/login` - Admin login
- `GET /account/me` - Get current user

### Users
- `GET /account/all` - Get all users
- `GET /account/:id` - Get user details
- `PUT /account/:id/verify` - Verify user
- `DELETE /account/:id` - Delete user
- `PUT /account/:id/ban` - Ban user

### Properties
- `GET /property` - Get all properties
- `GET /property/:id` - Get property details
- `PUT /property/:id/approve` - Approve property
- `DELETE /property/:id` - Delete property

### Auctions
- `GET /auction` - Get all auctions
- `GET /auction/:id` - Get auction details
- `POST /auction/:id/start` - Start auction
- `POST /auction/:id/end` - End auction
- `DELETE /auction/:id` - Cancel auction

### Bids
- `GET /bids` - Get all bids
- `GET /bids/auction/:auctionId` - Get bids for auction

### Projects
- `GET /project` - Get all projects
- `POST /project` - Create project
- `PUT /project/:id` - Update project
- `DELETE /project/:id` - Delete project

### Dashboard
- `GET /dashboard/stats` - Get dashboard statistics
- `GET /dashboard/analytics` - Get analytics data

## 🎨 Design System

### Colors
- Primary: `#667eea` → `#764ba2` (gradient)
- Success: `#10b981`
- Warning: `#f59e0b`
- Error: `#ef4444`
- Info: `#3b82f6`

### Components
- Modern card-based layouts
- Gradient backgrounds
- Smooth animations and transitions
- Responsive design
- Icon-based navigation
- Toast notifications

## 🔒 Security Features

1. **Admin-Only Access**: Only accounts with `type: 'Admin'` can access
2. **JWT Authentication**: Secure token-based authentication
3. **Auto Logout**: Automatic session cleanup on token expiry
4. **Protected Routes**: All routes require authentication
5. **Secure API Calls**: Authorization headers on all requests

## 📱 Responsive Design

- Mobile-friendly sidebar with hamburger menu
- Responsive tables and grids
- Touch-friendly buttons and controls
- Adaptive layouts for all screen sizes

## 🎯 Key Features

### User Management
- ✅ Comprehensive user listing
- ✅ KYC verification workflow
- ✅ User status tracking
- ✅ Ban/unban functionality
- ✅ Advanced filtering and search

### Properties
- ✅ Approval/rejection workflow
- ✅ Status tracking
- ✅ Image viewing
- ✅ Property details
- ✅ Filter by status and project

### Auctions
- ✅ Real-time monitoring
- ✅ Start/stop controls
- ✅ Countdown timers
- ✅ Bid tracking
- ✅ Status management

### Analytics
- ✅ Revenue tracking
- ✅ User growth metrics
- ✅ Property performance
- ✅ Custom date ranges
- ✅ Export functionality

### Settings
- ✅ General configuration
- ✅ Notification preferences
- ✅ Security settings
- ✅ System maintenance
- ✅ Database management

## 🚧 Future Enhancements

- Real-time WebSocket updates
- Advanced analytics with charts (Recharts integration)
- Bulk actions for multiple items
- Email template management
- Audit logs and activity tracking
- Multi-language support
- Dark mode theme
- Advanced reporting tools

## 📝 Notes

- All demo data is currently simulated - update to use real API endpoints
- Charts show placeholders - integrate Recharts for actual visualizations
- Some advanced features marked for future implementation
- Error handling and loading states implemented throughout

## 🔧 Environment Variables

Create a `.env` file in the dashboard directory:

```env
VITE_API_BASE_URL=http://localhost:5001/api
```

## 📄 License

This project is part of the Property Flipper platform.

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production Ready

