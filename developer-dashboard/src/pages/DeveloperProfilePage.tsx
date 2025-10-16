import React, { useState, useEffect } from 'react';
import { developerApi, DeveloperProfile } from '../services/developerApi';
import { Camera, Save, User } from 'lucide-react';

const DeveloperProfilePage: React.FC = () => {
  const [profile, setProfile] = useState<DeveloperProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  const [formData, setFormData] = useState({
    bio: '',
    companyName: '',
    profileImageUrl: '',
    portfolioDescription: '',
  });

  const userId = parseInt(localStorage.getItem('userId') || '0');

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      const data = await developerApi.getProfile(userId);
      setProfile(data);
      setFormData({
        bio: data.bio || '',
        companyName: data.companyName || '',
        profileImageUrl: data.profileImageUrl || '',
        portfolioDescription: data.portfolioDescription || '',
      });
    } catch (error) {
      console.error('Error loading profile:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await developerApi.updateProfile(formData);
      alert('Profile updated successfully!');
      loadProfile();
    } catch (error) {
      console.error('Error updating profile:', error);
      alert('Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Developer Profile</h1>

      {/* Profile Card */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="flex items-center gap-6 mb-6">
          {/* Profile Image */}
          <div className="relative">
            {formData.profileImageUrl ? (
              <img
                src={formData.profileImageUrl}
                alt="Profile"
                className="w-24 h-24 rounded-full object-cover"
              />
            ) : (
              <div className="w-24 h-24 rounded-full bg-gray-200 flex items-center justify-center">
                <User className="w-12 h-12 text-gray-400" />
              </div>
            )}
            <button className="absolute bottom-0 right-0 p-2 bg-blue-600 text-white rounded-full hover:bg-blue-700">
              <Camera className="w-4 h-4" />
            </button>
          </div>

          {/* Basic Info */}
          <div>
            <h2 className="text-2xl font-bold">
              {profile?.firstName} {profile?.lastName}
            </h2>
            <p className="text-gray-600">{profile?.email}</p>
            <p className="text-gray-600">{profile?.phoneNumber}</p>
            <div className="flex items-center gap-2 mt-2">
              <span className="text-yellow-500">★</span>
              <span className="font-semibold">{profile?.rating.toFixed(1)}</span>
              <span className="text-gray-500">({profile?.totalRatings} reviews)</span>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 p-4 bg-gray-50 rounded-lg">
          <div className="text-center">
            <p className="text-2xl font-bold text-blue-600">{profile?.activeProjectsCount}</p>
            <p className="text-sm text-gray-600">Active Projects</p>
          </div>
          <div className="text-center">
            <p className="text-2xl font-bold text-green-600">{profile?.totalPropertiesCount}</p>
            <p className="text-sm text-gray-600">Total Properties</p>
          </div>
          <div className="text-center">
            <p className="text-2xl font-bold text-purple-600">{profile?.soldPropertiesCount}</p>
            <p className="text-sm text-gray-600">Properties Sold</p>
          </div>
        </div>
      </div>

      {/* Edit Form */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold mb-4">Edit Profile</h3>

        <div className="space-y-4">
          {/* Company Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Company Name
            </label>
            <input
              type="text"
              value={formData.companyName}
              onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Your Company Name"
            />
          </div>

          {/* Bio */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Bio
            </label>
            <textarea
              value={formData.bio}
              onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
              rows={4}
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Tell users about yourself..."
            />
          </div>

          {/* Portfolio Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Portfolio Description
            </label>
            <textarea
              value={formData.portfolioDescription}
              onChange={(e) => setFormData({ ...formData, portfolioDescription: e.target.value })}
              rows={4}
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Describe your portfolio and achievements..."
            />
          </div>

          {/* Profile Image URL */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Profile Image URL
            </label>
            <input
              type="text"
              value={formData.profileImageUrl}
              onChange={(e) => setFormData({ ...formData, profileImageUrl: e.target.value })}
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="https://example.com/image.jpg"
            />
          </div>

          {/* Save Button */}
          <button
            onClick={handleSave}
            disabled={saving}
            className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {saving ? (
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
            ) : (
              <>
                <Save className="w-5 h-5" />
                Save Profile
              </>
            )}
          </button>
        </div>
      </div>

      {/* Reviews Section */}
      {profile && profile.ratings.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6 mt-6">
          <h3 className="text-xl font-bold mb-4">Recent Reviews</h3>
          <div className="space-y-4">
            {profile.ratings.slice(0, 10).map((rating) => (
              <div key={rating.ratingId} className="border-b pb-4">
                <div className="flex items-center justify-between mb-2">
                  <div>
                    <p className="font-semibold">{rating.userName}</p>
                    <div className="flex items-center gap-1 mt-1">
                      {[...Array(5)].map((_, i) => (
                        <span key={i} className={i < rating.rating ? 'text-yellow-500' : 'text-gray-300'}>
                          ★
                        </span>
                      ))}
                    </div>
                  </div>
                  <span className="text-xs text-gray-500">
                    {new Date(rating.createdAt).toLocaleDateString()}
                  </span>
                </div>
                {rating.comment && (
                  <p className="text-sm text-gray-600">{rating.comment}</p>
                )}
                <span className="text-xs text-gray-500 mt-1 inline-block">
                  {rating.ratingType}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default DeveloperProfilePage;

