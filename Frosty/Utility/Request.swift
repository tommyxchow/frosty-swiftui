//
//  Request.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

struct Request {
    private static let session = URLSession.shared
    static let decoder = JSONDecoder()

    enum HTTPMethod: String {
        case GET
        case POST
    }

    static func perform(_ method: HTTPMethod, to url: URL, headers: [String: String]? = nil) async -> Data? {
        var request = URLRequest(url: url)

        switch method {
        case .GET:
            request.httpMethod = "GET"
        case .POST:
            request.httpMethod = "POST"
        }

        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
                print("ERROR: NON 200-LEVEL RESPONSE")
                return nil
            }

            return data
        } catch {
            print("Request failed to \(url)")
            return nil
        }
    }

    static func assetToUrl(requestedDataType: Asset, token: String? = nil) async throws -> [String: URL] {
        var registry = [String: URL]()

        guard let data = await getAsset(asset: requestedDataType, token: token) else {
            print("Failed to get API data for \(requestedDataType) :(")
            return registry
        }

        switch requestedDataType {
        case .emoteTwitchGlobal, .emoteTwitchChannel:
            let result = try decoder.decode(EmotesTwitch.self, from: data)
            for emote in result.data {
                registry[emote.name] = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(emote.id)/default/dark/3.0")!
            }
        case .emoteBTTVGlobal:
            let result = try decoder.decode([EmoteBTTVGlobal].self, from: data)
            for emote in result {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/3x")!
            }
        case .emoteBTTVChannel:
            let result = try decoder.decode(EmoteBTTVChannel.self, from: data)
            for emote in result.channelEmotes {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/3x")!
            }
            for emote in result.sharedEmotes {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/3x")!
            }
        case .emoteFFZGlobal, .emoteFFZChannel:
            let result = try decoder.decode([EmotesFFZ].self, from: data)
            for emote in result {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/frankerfacez_emote/\(emote.id)/4")!
            }
        case .badgeTwitchGlobal, .badgeTwitchChannel:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let result = try decoder.decode(Badges.self, from: data)
            for badge in result.data {
                for badgeVersion in badge.versions {
                    registry["\(badge.setId)/\(badgeVersion.id)"] = URL(string: badgeVersion.imageUrl4X)!
                }
            }
        }
        return registry
    }

    static func getAsset(asset: Asset, token: String?) async -> Data? {
        let endpoint: URL
        let headers: [String: String]?

        if let token = token {
            headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        } else {
            headers = nil
        }

        switch asset {
        case .emoteTwitchGlobal:
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes/global")!
        case .emoteTwitchChannel(let id):
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes?broadcaster_id=\(id)")!
        case .emoteBTTVGlobal:
            endpoint = URL(string: "https://api.betterttv.net/3/cached/emotes/global")!
        case .emoteBTTVChannel(let id):
            endpoint = URL(string: "https://api.betterttv.net/3/cached/users/twitch/\(id)")!
        case .emoteFFZGlobal:
            endpoint = URL(string: "https://api.betterttv.net/3/cached/frankerfacez/emotes/global")!
        case .emoteFFZChannel(let id):
            endpoint = URL(string: "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/\(id)")!
        case .badgeTwitchGlobal:
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/badges/global")!
        case .badgeTwitchChannel(let id):
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/badges?broadcaster_id=\(id)")!
        }

        if let data = await perform(.GET, to: endpoint, headers: headers) {
            return data
        } else {
            return nil
        }
    }

    static func getUser(login: String, token: String) async -> [User] {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        if let data = await perform(.GET, to: URL(string: "https://api.twitch.tv/helix/users?login=\(login)")!, headers: headers) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let result = try decoder.decode(Users.self, from: data)
                return result.data
            } catch {
                print("Failed to parse user.")
            }
        }
        return []
    }

    static func getGlobalAssets(token: String) async -> [String: URL] {
        var finalRegisty = [String: URL]()

        do {
            async let twitchGlobalEmotes = assetToUrl(requestedDataType: .emoteTwitchGlobal, token: token)
            async let bttvGlobalEmotes = assetToUrl(requestedDataType: .emoteBTTVGlobal)
            async let ffzGlobalEmotes = assetToUrl(requestedDataType: .emoteFFZGlobal)
            async let twitchGlobalBadges = assetToUrl(requestedDataType: .badgeTwitchGlobal, token: token)

            let registries = try await [twitchGlobalEmotes, bttvGlobalEmotes, ffzGlobalEmotes, twitchGlobalBadges]
            for registry in registries {
                finalRegisty.merge(registry) { _, new in new }
            }
        } catch {
            print("Failed to get global assets: ", error.localizedDescription)
        }
        return finalRegisty
    }

    static func getChannelAssets(token: String, id: String) async -> [String: URL] {
        var finalRegisty = [String: URL]()
        do {
            async let twitchChannelEmotes = assetToUrl(requestedDataType: .emoteTwitchChannel(id: id), token: token)
            async let bttvChannelEmotes = assetToUrl(requestedDataType: .emoteBTTVChannel(id: id))
            async let ffzChannelEmotes = assetToUrl(requestedDataType: .emoteFFZChannel(id: id))
            async let twitchChannelBadges = assetToUrl(requestedDataType: .badgeTwitchChannel(id: id), token: token)

            let registries = try await [twitchChannelEmotes, bttvChannelEmotes, ffzChannelEmotes, twitchChannelBadges]
            for registry in registries {
                finalRegisty.merge(registry) { _, new in new }
            }
        } catch {
            print("Failed to get channel assets: ", error.localizedDescription)
        }
        return finalRegisty
    }
}

enum Asset {
    case emoteTwitchGlobal
    case emoteTwitchChannel(id: String)
    case emoteBTTVGlobal
    case emoteBTTVChannel(id: String)
    case emoteFFZGlobal
    case emoteFFZChannel(id: String)
    case badgeTwitchGlobal
    case badgeTwitchChannel(id: String)
}
