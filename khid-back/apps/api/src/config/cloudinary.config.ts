import { Injectable, OnModuleInit } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';

@Injectable()
export class CloudinaryConfigService implements OnModuleInit {
  onModuleInit(): void {
    cloudinary.config({
      cloud_name: process.env['CLOUDINARY_CLOUD_NAME'] ?? '',
      api_key:    process.env['CLOUDINARY_API_KEY'] ?? '',
      api_secret: process.env['CLOUDINARY_API_SECRET'] ?? '',
      secure:     true,
    });
  }

  get client() {
    return cloudinary;
  }

  get folderProfiles(): string {
    return process.env['CLOUDINARY_FOLDER_PROFILES'] ?? 'profile-images';
  }

  get folderMedia(): string {
    return process.env['CLOUDINARY_FOLDER_MEDIA'] ?? 'service-media';
  }

  get folderAudio(): string {
    return process.env['CLOUDINARY_FOLDER_AUDIO'] ?? 'audio-recordings';
  }

  get folderDocuments(): string {
    return process.env['CLOUDINARY_FOLDER_DOCUMENTS'] ?? 'verification-docs';
  }
}
