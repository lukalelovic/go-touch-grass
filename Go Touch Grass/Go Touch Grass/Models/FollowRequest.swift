//
//  FollowRequest.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 1/24/26.
//

import Foundation

// MARK: - Follow Request Model
struct FollowRequest: Identifiable, Codable {
    let id: Int
    let requesterId: UUID
    let requestedId: UUID
    let status: FollowRequestStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case requestedId = "requested_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Follow Request Status
enum FollowRequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

// MARK: - Follow Request with User Info
struct FollowRequestWithUser: Identifiable {
    let id: Int
    let userId: UUID
    let username: String
    let profilePictureUrl: String?
    let createdAt: Date

    init(id: Int, userId: UUID, username: String, profilePictureUrl: String?, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.username = username
        self.profilePictureUrl = profilePictureUrl
        self.createdAt = createdAt
    }
}

// MARK: - Response types for database functions
struct FollowRequestResponse: Codable {
    let requestId: Int
    let requesterId: UUID
    let requesterUsername: String
    let requesterProfilePictureUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case requesterId = "requester_id"
        case requesterUsername = "requester_username"
        case requesterProfilePictureUrl = "requester_profile_picture_url"
        case createdAt = "created_at"
    }
}

struct SentFollowRequestResponse: Codable {
    let requestId: Int
    let requestedId: UUID
    let requestedUsername: String
    let requestedProfilePictureUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case requestedId = "requested_id"
        case requestedUsername = "requested_username"
        case requestedProfilePictureUrl = "requested_profile_picture_url"
        case createdAt = "created_at"
    }
}

struct SendFollowRequestResult: Codable {
    let success: Bool
    let isDirectFollow: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case success
        case isDirectFollow = "is_direct_follow"
        case message
    }
}
