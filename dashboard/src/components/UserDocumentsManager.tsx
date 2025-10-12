import React, { useState, useEffect } from 'react';
import { documentsApi } from '../services/api';
import { UserDocument } from '../types';
import { useToast } from '../contexts/ToastContext';
import { FileText, Upload, Trash2, Eye, Calendar, Image as ImageIcon, Download } from 'lucide-react';

interface UserDocumentsManagerProps {
  userId: number;
  userName?: string;
  isAdmin?: boolean;
}

const USER_DOC_TYPES = [
  { value: 'ID_Front', label: 'ID Card (Front)', icon: '🪪' },
  { value: 'ID_Back', label: 'ID Card (Back)', icon: '🪪' },
  { value: 'Passport', label: 'Passport', icon: '📘' },
  { value: 'ProofOfAddress', label: 'Proof of Address', icon: '📄' },
  { value: 'Selfie', label: 'Selfie with ID', icon: '🤳' },
  { value: 'Other', label: 'Other Document', icon: '📋' },
];

export default function UserDocumentsManager({ userId, userName, isAdmin = false }: UserDocumentsManagerProps) {
  const [documents, setDocuments] = useState<UserDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [selectedDocType, setSelectedDocType] = useState('ID_Front');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [viewingImage, setViewingImage] = useState<string | null>(null);
  const toast = useToast();

  useEffect(() => {
    console.log('🟢 UserDocumentsManager mounted', { userId, userName, isAdmin });
    if (userId) {
      loadDocuments();
    }
  }, [userId]);

  const loadDocuments = async () => {
    try {
      setLoading(true);
      console.log(`🔍 Loading documents for userId: ${userId}`);
      
      const docs = await documentsApi.getUserDocuments(userId);
      
      console.log(`📥 Received ${docs.length} documents:`, docs);
      setDocuments(docs);
    } catch (error: any) {
      console.error('❌ Error loading documents:', error);
      toast.error(error.response?.data?.message || 'Failed to load documents');
    } finally {
      setLoading(false);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 32 * 1024 * 1024) {
        toast.error('File size must be less than 32MB');
        return;
      }
      setSelectedFile(file);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      toast.error('Please select a file');
      return;
    }

    try {
      setUploading(true);
      await documentsApi.uploadUserDocument(selectedFile, selectedDocType);
      toast.success('Document uploaded successfully');
      setSelectedFile(null);
      
      const fileInput = document.getElementById('kyc-file-input') as HTMLInputElement;
      if (fileInput) fileInput.value = '';
      
      loadDocuments();
    } catch (error: any) {
      console.error('❌ Error uploading document:', error);
      toast.error(error.response?.data?.message || 'Failed to upload document');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (docId: number) => {
    if (!confirm('Are you sure you want to delete this document?')) {
      return;
    }

    try {
      await documentsApi.deleteUserDocument(docId);
      toast.success('Document deleted successfully');
      loadDocuments();
    } catch (error: any) {
      console.error('❌ Error deleting document:', error);
      toast.error(error.response?.data?.message || 'Failed to delete document');
    }
  };

  const getDocTypeInfo = (docType: string) => {
    return USER_DOC_TYPES.find(t => t.value === docType) || { label: docType, icon: '📄' };
  };

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '3rem'
      }}>
        <div style={{
          width: '3rem',
          height: '3rem',
          border: '4px solid #f3f4f6',
          borderTop: '4px solid #667eea',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite'
        }}></div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Header */}
      {userName && (
        <div style={{
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          borderRadius: '1rem',
          padding: '1.5rem',
          color: 'white',
          boxShadow: '0 4px 6px rgba(102, 126, 234, 0.3)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
            <FileText style={{ width: '1.5rem', height: '1.5rem' }} />
            <h2 style={{ fontSize: '1.5rem', fontWeight: '700', margin: 0 }}>
              KYC Documents for {userName}
            </h2>
          </div>
          <p style={{ fontSize: '0.875rem', opacity: 0.9, margin: 0 }}>
            Identity verification documents and supporting materials
          </p>
        </div>
      )}

      {/* Upload Section - Admin Only */}
      {isAdmin && (
        <div style={{
          backgroundColor: 'white',
          borderRadius: '1rem',
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb',
          padding: '1.5rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.25rem' }}>
            <div style={{
              width: '2.5rem',
              height: '2.5rem',
              borderRadius: '0.5rem',
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <Upload style={{ width: '1.25rem', height: '1.25rem', color: 'white' }} />
            </div>
            <h3 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', margin: 0 }}>
              Upload KYC Document
            </h3>
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <div>
              <label style={{
                display: 'block',
                fontSize: '0.875rem',
                fontWeight: '500',
                color: '#374151',
                marginBottom: '0.5rem'
              }}>
                Document Type
              </label>
              <select
                value={selectedDocType}
                onChange={(e) => setSelectedDocType(e.target.value)}
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #d1d5db',
                  borderRadius: '0.5rem',
                  fontSize: '0.875rem',
                  outline: 'none',
                  transition: 'all 0.2s'
                }}
                onFocus={(e) => e.target.style.borderColor = '#667eea'}
                onBlur={(e) => e.target.style.borderColor = '#d1d5db'}
              >
                {USER_DOC_TYPES.map(type => (
                  <option key={type.value} value={type.value}>
                    {type.icon} {type.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label style={{
                display: 'block',
                fontSize: '0.875rem',
                fontWeight: '500',
                color: '#374151',
                marginBottom: '0.5rem'
              }}>
                File (Max 32MB - Images or PDF)
              </label>
              <input
                id="kyc-file-input"
                type="file"
                accept="image/*,.pdf"
                onChange={handleFileSelect}
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #d1d5db',
                  borderRadius: '0.5rem',
                  fontSize: '0.875rem',
                  outline: 'none',
                  cursor: 'pointer'
                }}
              />
              {selectedFile && (
                <p style={{
                  marginTop: '0.5rem',
                  fontSize: '0.875rem',
                  color: '#6b7280'
                }}>
                  Selected: {selectedFile.name} ({(selectedFile.size / 1024 / 1024).toFixed(2)} MB)
                </p>
              )}
            </div>

            <button
              onClick={handleUpload}
              disabled={uploading || !selectedFile}
              style={{
                width: '100%',
                padding: '0.75rem 1rem',
                background: uploading || !selectedFile 
                  ? '#9ca3af' 
                  : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                color: 'white',
                border: 'none',
                borderRadius: '0.5rem',
                fontSize: '0.875rem',
                fontWeight: '600',
                cursor: uploading || !selectedFile ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem',
                transition: 'all 0.2s',
                boxShadow: uploading || !selectedFile ? 'none' : '0 4px 6px rgba(102, 126, 234, 0.25)'
              }}
              onMouseEnter={(e) => {
                if (!uploading && selectedFile) {
                  e.currentTarget.style.transform = 'translateY(-2px)';
                  e.currentTarget.style.boxShadow = '0 6px 12px rgba(102, 126, 234, 0.35)';
                }
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = uploading || !selectedFile ? 'none' : '0 4px 6px rgba(102, 126, 234, 0.25)';
              }}
            >
              {uploading ? (
                <>
                  <div style={{
                    width: '1.25rem',
                    height: '1.25rem',
                    border: '2px solid white',
                    borderTop: '2px solid transparent',
                    borderRadius: '50%',
                    animation: 'spin 1s linear infinite'
                  }}></div>
                  Uploading...
                </>
              ) : (
                <>
                  <Upload style={{ width: '1.25rem', height: '1.25rem' }} />
                  Upload Document
                </>
              )}
            </button>
          </div>
        </div>
      )}

      {/* Documents Grid */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '1rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        border: '1px solid #e5e7eb',
        padding: '1.5rem'
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '1.5rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div style={{
              width: '2.5rem',
              height: '2.5rem',
              borderRadius: '0.5rem',
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <ImageIcon style={{ width: '1.25rem', height: '1.25rem', color: 'white' }} />
            </div>
            <div>
              <h3 style={{
                fontSize: '1.125rem',
                fontWeight: '600',
                color: '#111827',
                margin: 0
              }}>
                Uploaded Documents
              </h3>
              <p style={{
                fontSize: '0.875rem',
                color: '#6b7280',
                margin: 0
              }}>
                {documents.length} {documents.length === 1 ? 'document' : 'documents'} uploaded
              </p>
            </div>
          </div>
        </div>

        {documents.length === 0 ? (
          <div style={{
            textAlign: 'center',
            padding: '3rem 1rem',
            backgroundColor: '#f9fafb',
            borderRadius: '0.75rem',
            border: '2px dashed #d1d5db'
          }}>
            <div style={{
              width: '4rem',
              height: '4rem',
              borderRadius: '50%',
              backgroundColor: '#e5e7eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 1rem'
            }}>
              <FileText style={{ width: '2rem', height: '2rem', color: '#9ca3af' }} />
            </div>
            <p style={{
              fontSize: '1rem',
              fontWeight: '500',
              color: '#6b7280',
              margin: '0 0 0.5rem 0'
            }}>
              No documents uploaded yet
            </p>
            <p style={{
              fontSize: '0.875rem',
              color: '#9ca3af',
              margin: 0
            }}>
              {isAdmin ? 'Upload KYC documents to verify this user' : 'Upload your identity documents to get verified'}
            </p>
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
            gap: '1.25rem'
          }}>
            {documents.map((doc) => {
              const docInfo = getDocTypeInfo(doc.docType);
              return (
                <div
                  key={doc.docId}
                  style={{
                    border: '1px solid #e5e7eb',
                    borderRadius: '0.75rem',
                    overflow: 'hidden',
                    transition: 'all 0.2s',
                    backgroundColor: 'white',
                    cursor: 'pointer'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.boxShadow = '0 10px 15px rgba(0, 0, 0, 0.1)';
                    e.currentTarget.style.transform = 'translateY(-4px)';
                    e.currentTarget.style.borderColor = '#667eea';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.boxShadow = 'none';
                    e.currentTarget.style.transform = 'translateY(0)';
                    e.currentTarget.style.borderColor = '#e5e7eb';
                  }}
                >
                  {/* Image Preview */}
                  <div
                    onClick={() => setViewingImage(doc.imgUrl)}
                    style={{
                      position: 'relative',
                      backgroundColor: '#f3f4f6',
                      aspectRatio: '16/9',
                      overflow: 'hidden'
                    }}
                  >
                    <img
                      src={doc.imgUrl}
                      alt={doc.docType}
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                        transition: 'transform 0.3s'
                      }}
                      onMouseEnter={(e) => {
                        (e.target as HTMLImageElement).style.transform = 'scale(1.05)';
                      }}
                      onMouseLeave={(e) => {
                        (e.target as HTMLImageElement).style.transform = 'scale(1)';
                      }}
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23e5e7eb" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" text-anchor="middle" dy=".3em" font-size="14"%3E📄 Document%3C/text%3E%3C/svg%3E';
                      }}
                    />
                    <div style={{
                      position: 'absolute',
                      top: '0.5rem',
                      left: '0.5rem',
                      backgroundColor: 'rgba(0, 0, 0, 0.75)',
                      backdropFilter: 'blur(4px)',
                      borderRadius: '0.5rem',
                      padding: '0.25rem 0.75rem',
                      fontSize: '0.875rem',
                      fontWeight: '600',
                      color: 'white'
                    }}>
                      {docInfo.icon} {docInfo.label}
                    </div>
                  </div>

                  {/* Document Info */}
                  <div style={{ padding: '1rem' }}>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      marginBottom: '0.75rem'
                    }}>
                      <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        fontSize: '0.75rem',
                        color: '#6b7280'
                      }}>
                        <Calendar style={{ width: '0.875rem', height: '0.875rem' }} />
                        {new Date(doc.uploadedAt).toLocaleDateString('en-US', {
                          month: '2-digit',
                          day: '2-digit',
                          year: 'numeric'
                        })}
                      </div>
                      {isAdmin && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDelete(doc.docId);
                          }}
                          style={{
                            padding: '0.375rem',
                            borderRadius: '0.375rem',
                            border: 'none',
                            backgroundColor: '#fef2f2',
                            color: '#dc2626',
                            cursor: 'pointer',
                            transition: 'all 0.2s'
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor = '#fee2e2';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor = '#fef2f2';
                          }}
                          title="Delete document"
                        >
                          <Trash2 style={{ width: '1rem', height: '1rem' }} />
                        </button>
                      )}
                    </div>

                    <div style={{
                      display: 'grid',
                      gridTemplateColumns: '1fr 1fr',
                      gap: '0.5rem'
                    }}>
                      <button
                        onClick={() => setViewingImage(doc.imgUrl)}
                        style={{
                          padding: '0.5rem',
                          borderRadius: '0.5rem',
                          border: '1px solid #e5e7eb',
                          backgroundColor: '#f9fafb',
                          color: '#374151',
                          fontSize: '0.75rem',
                          fontWeight: '500',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '0.375rem',
                          transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.backgroundColor = '#667eea';
                          e.currentTarget.style.color = 'white';
                          e.currentTarget.style.borderColor = '#667eea';
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.backgroundColor = '#f9fafb';
                          e.currentTarget.style.color = '#374151';
                          e.currentTarget.style.borderColor = '#e5e7eb';
                        }}
                      >
                        <Eye style={{ width: '0.875rem', height: '0.875rem' }} />
                        View
                      </button>
                      <a
                        href={doc.imgUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          padding: '0.5rem',
                          borderRadius: '0.5rem',
                          border: '1px solid #e5e7eb',
                          backgroundColor: '#f9fafb',
                          color: '#374151',
                          fontSize: '0.75rem',
                          fontWeight: '500',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '0.375rem',
                          transition: 'all 0.2s',
                          textDecoration: 'none'
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.backgroundColor = '#10b981';
                          e.currentTarget.style.color = 'white';
                          e.currentTarget.style.borderColor = '#10b981';
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.backgroundColor = '#f9fafb';
                          e.currentTarget.style.color = '#374151';
                          e.currentTarget.style.borderColor = '#e5e7eb';
                        }}
                      >
                        <Download style={{ width: '0.875rem', height: '0.875rem' }} />
                        Download
                      </a>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Image Viewer Modal */}
      {viewingImage && (
        <div
          onClick={() => setViewingImage(null)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.9)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '2rem',
            animation: 'fadeIn 0.2s ease-in-out'
          }}
        >
          <div style={{
            maxWidth: '90vw',
            maxHeight: '90vh',
            position: 'relative'
          }}>
            <img
              src={viewingImage}
              alt="Document"
              onClick={(e) => e.stopPropagation()}
              style={{
                maxWidth: '100%',
                maxHeight: '90vh',
                objectFit: 'contain',
                borderRadius: '0.5rem',
                boxShadow: '0 25px 50px rgba(0, 0, 0, 0.5)'
              }}
            />
            <button
              onClick={() => setViewingImage(null)}
              style={{
                position: 'absolute',
                top: '-1rem',
                right: '-1rem',
                width: '3rem',
                height: '3rem',
                borderRadius: '50%',
                backgroundColor: 'white',
                border: 'none',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '1.5rem',
                fontWeight: '700',
                color: '#111827',
                boxShadow: '0 4px 6px rgba(0, 0, 0, 0.3)',
                transition: 'all 0.2s'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = '#dc2626';
                e.currentTarget.style.color = 'white';
                e.currentTarget.style.transform = 'scale(1.1)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'white';
                e.currentTarget.style.color = '#111827';
                e.currentTarget.style.transform = 'scale(1)';
              }}
            >
              ✕
            </button>
          </div>
          
          {/* Download button in modal */}
          <a
            href={viewingImage}
            download
            target="_blank"
            rel="noopener noreferrer"
            onClick={(e) => e.stopPropagation()}
            style={{
              position: 'absolute',
              bottom: '2rem',
              right: '2rem',
              padding: '0.75rem 1.5rem',
              borderRadius: '0.5rem',
              background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
              color: 'white',
              fontSize: '0.875rem',
              fontWeight: '600',
              textDecoration: 'none',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              boxShadow: '0 4px 6px rgba(16, 185, 129, 0.3)',
              transition: 'all 0.2s'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 6px 12px rgba(16, 185, 129, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 6px rgba(16, 185, 129, 0.3)';
            }}
          >
            <Download style={{ width: '1rem', height: '1rem' }} />
            Download Image
          </a>
        </div>
      )}

      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      `}</style>
    </div>
  );
}
