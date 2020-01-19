import SwiftUI
import UIKit
import Contacts

struct PageControl: UIViewRepresentable {
    @Binding var numberOfPages: Int
    @Binding var currentPage: Int
    var colorScheme: ColorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateCurrentPage(sender:)),
            for: .valueChanged)
        control.hidesForSinglePage = true
        control.currentPageIndicatorTintColor = colorScheme == .light ? .black : .white
        control.pageIndicatorTintColor = .gray
        return control
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = currentPage
    }

    class Coordinator: NSObject {
        var control: PageControl

        init(_ control: PageControl) {
            self.control = control
        }

        @objc func updateCurrentPage(sender: UIPageControl) {
            control.currentPage = sender.currentPage
        }
    }
}

var prevPage: Int = 0

struct PageViewController: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if (prevPage < currentPage) {
            pageViewController.setViewControllers(
                [views.views[currentPage]], direction: .forward, animated: true)
        } else if prevPage == currentPage {
            pageViewController.setViewControllers(
                [views.views[currentPage]], direction: .forward, animated: true)
        } else {
            pageViewController.setViewControllers(
                [views.views[currentPage]], direction: .reverse, animated: true)
        }
        
        
        prevPage = currentPage
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController

        init(_ pageViewController: PageViewController) {
            self.parent = pageViewController
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController) -> UIViewController?
        {
            guard let index = views.views.firstIndex(of: viewController) else {
                return nil
            }
            if index == 0 {
                return nil //parent.controllers.last
            }
            return views.views[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController) -> UIViewController?
        {
            guard let index = views.views.firstIndex(of: viewController) else {
                return nil
            }
            if index + 1 == views.views.count {
                return nil //UIHostingController(rootView: EditView(selectedContact: new())) //parent.controllers.first
            }
            return views.views[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
                let visibleViewController = pageViewController.viewControllers?.first,
                let index = views.views.firstIndex(of: visibleViewController)
            {
                parent.currentPage = index
            }
        }
        
        func new() -> CNMutableContact {
            let c = CNMutableContact();
            contacts.contacts.insert(c, at: 0);
            return c;
        }
    }
}

struct SearchBar: UIViewRepresentable {

    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}
