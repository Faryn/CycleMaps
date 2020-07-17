//
//  MapStyleView.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 04.07.20.
//  Copyright © 2020 Paul Pfeiffer. All rights reserved.
//

import SwiftUI
import MapKit

struct MapStyleView: View {
    var mapStyles: [TileSource] = []
    //  @Binding var selectionKeeper: Int
    var body: some View {
        NavigationView {
            VStack {
                List(){
                    ForEach(0..<mapStyles.count) { i in
                        MapStyleCell(mapStyle: self.mapStyles[i],
                                     isSelected: i == 0,
                                     action: { self.changeSelection(index: i) })
                    }
                }
                //MapView()
            }

        }
    }
    
    func changeSelection(index: Int){

    }
}


struct MapStyleCell: View {
    var mapStyle: TileSource
    var isSelected: Bool // Added this
    var Action: () -> Void

    // Added this -------v
    init(mapStyle: TileSource, isSelected: Bool, action: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.mapStyle = mapStyle
        self.isSelected = isSelected  // Added this
        self.Action = action
    }

    var body: some View {
        Button(mapStyle.name, action: {
            self.Action()
        })
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        // Changed this ------------------------------^
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //2
        MapStyleView(mapStyles: [TileSource.cyclosm, TileSource.apple, TileSource.openStreetMap])
    }
}
#endif
