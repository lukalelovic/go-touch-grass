//
//  TouchGrassWidgetBundle.swift
//  Go Touch Grass
//
//  Widget Bundle Entry Point
//

import WidgetKit
import SwiftUI

@main
struct TouchGrassWidgetBundle: WidgetBundle {
    var body: some Widget {
        TouchGrassWidget()
        TouchGrassLiveActivity()
    }
}
