//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct ReceivedTransfersAPIItemServiceAdapter: ItemService {
    let api: TransfersAPI
    let select: (Transfer) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        api.loadTransfers { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map ({ transfers in
                    transfers.filter({
                        !$0.isSender
                    }) .map({ transfer in
                        ItemListViewModel(transfer: transfer, longDateStyle: false, selection: {
                            select(transfer)
                        })
                    })
                }))
            }
        }
    }
}
