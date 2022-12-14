//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct FriendsAPIItemServiceAdapter: ItemService {
    let api: FriendsAPI
    let cache: FriendsCache
    let select: (Friend) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        api.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map { items in
                    cache.save(items)
                    return items.map{ item in
                        ItemListViewModel(friend: item) {
                            select(item)
                        }
                    }
                })
            }
        }
    }
}
