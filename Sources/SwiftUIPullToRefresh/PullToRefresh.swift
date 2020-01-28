//
//  Spinner.swift
//  PullToRefresh
//
//  Created by András Samu on 2019. 09. 15..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI


@available(iOS 13.0, *)
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
    }
}


@available(iOS 13.0, *)
public struct RefreshableList<Content: View>: View {
    @Binding var showRefreshView: Bool
    @Binding var pullStatus: CGFloat
    @State var showDone: Bool = false
    let action: () -> Void
    let content: () -> Content
    init(showRefreshView: Binding<Bool>, pullStatus: Binding<CGFloat>, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self._showRefreshView = showRefreshView
        self._pullStatus = pullStatus
        self.action = action
        self.content = content
        UITableViewHeaderFooterView.appearance().tintColor = UIColor.clear
    }
    
    public var body: some View {
        
        List{
            Section(header: PullToRefreshView(showRefreshView: $showRefreshView, pullStatus: $pullStatus))
            {
             content()
            }
        }
        .offset(y: -40)
        .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
            guard let bounds = values.first?.bounds else { return }
            self.pullStatus = CGFloat((bounds.origin.y - 106) / 80)
            self.refresh(offset: bounds.origin.y)
        }
    }
    
    func refresh(offset: CGFloat) {
        if(offset > 185 + 40 && self.showRefreshView == false) {
            self.showRefreshView = true
            DispatchQueue.main.async {
                self.action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showRefreshView = false
                    self.showDone = true
                }
            }
            
        }
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
struct RefreshView: View {
    @Binding var isRefreshing:Bool
    @Binding var status: CGFloat
    @Binding var showDone: Bool
    var body: some View {
        HStack{
            VStack(alignment: .center){
                if (!isRefreshing) {
                    Spinner(percentage: $status)
                }else{
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                if showDone {
                    Text("Done").font(.caption)
                } else {
                    Text(isRefreshing ? "Loading" : "Pull to refresh").font(.caption)

                }
            }
        }
    }
}

@available(iOS 13.0, *)
struct PullToRefreshView: View {
    @Binding var showRefreshView: Bool
    @Binding var pullStatus: CGFloat
    var body: some View {
        GeometryReader{ geometry in
            RefreshView(isRefreshing: self.$showRefreshView, status: self.$pullStatus)
                .opacity(Double((geometry.frame(in: CoordinateSpace.global).origin.y - 106) / 80)).preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(bounds: geometry.frame(in: CoordinateSpace.global))])
                .offset(y: -70)
        }
        .offset(y: -20)
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
struct Spinner_Previews: PreviewProvider {
    static var previews: some View {
        Spinner(percentage: .constant(1))
    }
}
