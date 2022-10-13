//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct FriendsCacheItemServiceAdapter: ItemService {
    let cache: FriendsCache
    let select: (Friend) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        cache.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map { items in
                    items.map{ item in
                        ItemListViewModel(friend: item) {
                            select(item)
                        }
                    }
                })
            }
        }
    }
}

