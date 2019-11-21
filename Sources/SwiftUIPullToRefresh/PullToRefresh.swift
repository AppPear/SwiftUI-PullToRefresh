//
//  Spinner.swift
//  PullToRefresh
//
//  Created by András Samu on 2019. 09. 15..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct RefreshableNavigationView<Content: View>: View {
    let content: () -> Content
    let action: () -> Void
    @State public var showRefreshView: Bool = false
    @State public var pullStatus: CGFloat = 0
    private var title: String

    public init(title:String, action: @escaping () -> Void ,@ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.action = action
        self.content = content
    }
    
    public var body: some View {
        NavigationView{
            RefreshableList(showRefreshView: $showRefreshView, pullStatus: $pullStatus, action: self.action) {
                self.content()
            }.navigationBarTitle(title)
        }
        .offset(x: 0, y: self.showRefreshView ? 34 : 0)
        .onAppear{
            UITableView.appearance().separatorColor = .clear
        }
    }
}

public struct RefreshableList<Content: View>: View {
    @Binding var showRefreshView: Bool
    @Binding var pullStatus: CGFloat
    let action: () -> Void
    let content: () -> Content
    init(showRefreshView: Binding<Bool>, pullStatus: Binding<CGFloat>, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self._showRefreshView = showRefreshView
        self._pullStatus = pullStatus
        self.action = action
        self.content = content
    }
    
    public var body: some View {
        List{
            PullToRefreshView(showRefreshView: $showRefreshView, pullStatus: $pullStatus)
            content()
        }
        .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
            guard let bounds = values.first?.bounds else { return }
            self.pullStatus = CGFloat((bounds.origin.y - 106) / 80)
            self.refresh(offset: bounds.origin.y)
        }.offset(x: 0, y: -40)
    }
    
    func refresh(offset: CGFloat) {
        if(offset > 185 && self.showRefreshView == false) {
            self.showRefreshView = true
            DispatchQueue.main.async {
                self.action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showRefreshView = false
                }
            }
            
        }
    }
}

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

struct RefreshView: View {
    @Binding var isRefreshing:Bool
    @Binding var status: CGFloat
    var body: some View {
        HStack{
            Spacer()
            VStack(alignment: .center){
                if (!isRefreshing) {
                    Spinner(percentage: $status)
                }else{
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                Text(isRefreshing ? "Loading" : "Pull to refresh").font(.caption)
            }
            Spacer()
        }
    }
}

struct PullToRefreshView: View {
    @Binding var showRefreshView: Bool
    @Binding var pullStatus: CGFloat
    var body: some View {
        GeometryReader{ geometry in
            RefreshView(isRefreshing: self.$showRefreshView, status: self.$pullStatus)
                .opacity(Double((geometry.frame(in: CoordinateSpace.global).origin.y - 106) / 80)).preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(bounds: geometry.frame(in: CoordinateSpace.global))])
                .offset(x: 0, y: -90)
        }
    }
}

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

struct Spinner_Previews: PreviewProvider {
    static var previews: some View {
        Spinner(percentage: .constant(1))
    }
}
