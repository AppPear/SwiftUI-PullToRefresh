//
//  Spinner.swift
//  PullToRefresh
//
//  Created by András Samu on 2019. 09. 15..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, *)
class RefreshData: ObservableObject {
    @Published var showText: String
    @Published var showRefreshView: Bool {
        didSet {
            self.showText = "Loading"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.showRefreshView {
                    self.showRefreshView = false
                    self.showDone = true
                    self.showText = "Done"
                }
            }
        }
    }
    @Published var pullStatus: CGFloat
    @Published var showDone: Bool {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if self.showDone {
                    self.showDone = false
                    self.showText = "Pull to refresh"
                }
            }
        }
    }
    
    
    init() {
        self.showRefreshView = false
        self.pullStatus = 0
        self.showDone = false
        self.showText = "Pull to refresh"
    }
}


@available(iOS 13.0, macOS 10.15, *)
public struct RefreshableNavigationView<Content: View>: View {
    let content: () -> Content
    let action: () -> Void
    @ObservedObject var data = RefreshData()
    private var title: String

    public init(title:String, action: @escaping () -> Void ,@ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.action = action
        self.content = content
    }
    
    public var body: some View {
        NavigationView{
            RefreshableList(data: data, action: self.action) {
                self.content()
            }.navigationBarTitle(title)
        }
    }
}


@available(iOS 13.0, macOS 10.15, *)
public struct RefreshableList<Content: View>: View {
    @ObservedObject var data: RefreshData
    let action: () -> Void
    let content: () -> Content
    init(data: RefreshData, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.data = data
        self.action = action
        self.content = content
        UITableViewHeaderFooterView.appearance().tintColor = UIColor.clear
    }
    
    public var body: some View {
        
        List{
            Section(header: PullToRefreshView(data: self.data)) {
             content()
            }
        }
        .offset(y: -40)
        .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
            guard let bounds = values.first?.bounds else { return }
            self.data.pullStatus = CGFloat((bounds.origin.y - 106) / 80)
            self.refresh(offset: bounds.origin.y)
        }
    }
    
    func refresh(offset: CGFloat) {
        if(offset > 185 + 40 && self.data.showRefreshView == false) {
            self.data.showRefreshView = true
            DispatchQueue.main.async {
                self.action()
            }
            
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct Spinner: View {
    @Binding var percentage: CGFloat
    var body: some View {
        GeometryReader{ geometry in
            ForEach(1...10, id: \.self) { i in
                Rectangle()
                    .fill(Color.gray)
                    .cornerRadius(1)
                    .frame(width: 2.5, height: 8)
                    .opacity(self.percentage * 10 >= CGFloat(i) ? Double(i)/10.0 : 0)
                    .offset(x: 0, y: -8)
                    .rotationEffect(.degrees(Double(36 * i)), anchor: .bottom)
            }.offset(x: 20, y: 12)
        }.frame(width: 40, height: 40)
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct RefreshView: View {
    @ObservedObject var data: RefreshData
    var body: some View {
        HStack() {
            VStack(alignment: .center){
                if data.showText == "done" {
                                   Image(systemName: "checkmark.circle")
                                       .foregroundColor(Color.green)
                               }
                
                if (!data.showRefreshView) {
                    Spinner(percentage: self.$data.pullStatus)
                }
                else {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                Text(self.data.showText).font(.caption)
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct PullToRefreshView: View {
    @ObservedObject var data: RefreshData
    var body: some View {
        GeometryReader{ geometry in
            RefreshView(data: self.data)
                .opacity(Double((geometry.frame(in: CoordinateSpace.global).origin.y - 106) / 80)).preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(bounds: geometry.frame(in: CoordinateSpace.global))])
                .offset(y: -70)
        }
        .offset(y: -20)
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct RefreshableKeyTypes {
    
    struct PrefData: Equatable {
        let bounds: CGRect
    }

    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct Spinner_Previews: PreviewProvider {
    static var previews: some View {
        Spinner(percentage: .constant(1))
    }
}
