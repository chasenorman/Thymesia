//
//  ContentView.swift
//  Thymesia
//
//  Created by Chase Norman on 1/2/20.
//  Copyright © 2020 Chase Norman. All rights reserved.
//

import SwiftUI
import Contacts

let keys = [CNContactInstantMessageAddressesKey,CNContactGivenNameKey,CNContactTypeKey,CNContactDatesKey,CNContactBirthdayKey,CNContactNicknameKey,CNContactRelationsKey,CNContactIdentifierKey,CNContactJobTitleKey,CNContactImageDataKey,CNContactFamilyNameKey,CNContactMiddleNameKey,CNContactNamePrefixKey,CNContactNameSuffixKey,CNContactPhoneNumbersKey,CNContactUrlAddressesKey,CNContactDepartmentNameKey,CNContactEmailAddressesKey,CNContactSocialProfilesKey,CNContactPostalAddressesKey,CNContactOrganizationNameKey,CNContactPhoneticGivenNameKey,CNContactImageDataAvailableKey,CNContactPhoneticFamilyNameKey,CNContactPhoneticMiddleNameKey,CNContactPreviousFamilyNameKey,CNContactThumbnailImageDataKey,CNContactNonGregorianBirthdayKey,CNContactPhoneticOrganizationNameKey] as [CNKeyDescriptor]

public class Contacts: ObservableObject {
    @Published var contacts = [CNMutableContact]()
    
    public init(){
        load()
    }
    
    func load() {
        self.contacts = []
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        try! CNContactStore().enumerateContacts(with: request) {
            (contact, stop) in
            self.contacts.insert(contact.mutableCopy() as! CNMutableContact, at: 0)
        }
    }
}

public class Views: ObservableObject {
    @Published var views: [UIViewController] = [UIViewController()];
    @Published var pages = 1
    @Published var currentPage = 0
}

let contacts = Contacts()
let views = Views()

func delete(at offsets: IndexSet) {
    let save = CNSaveRequest()
    for i in offsets {
        save.delete(contacts.contacts[i]);
    }
    try! CNContactStore().execute(save);
    contacts.contacts.remove(atOffsets: offsets)
}

func new() -> CNMutableContact {
    let c = CNMutableContact();
    contacts.contacts.insert(c, at: 0);
    let save = CNSaveRequest()
    save.add(c, toContainerWithIdentifier: nil)
    try! CNContactStore().execute(save);
    return c;
}

func name(_ contact: CNMutableContact?) -> String {
    if let c = contact {
        return nameFormatter.string(from: c) ?? "No Name"
    }
    return "null"
}

private let nameFormatter: CNContactFormatter = {
    let formatter = CNContactFormatter()
    formatter.style = .fullName
    return formatter;
}()

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

struct ContentView: View {
    @Environment (\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject var views: Views;
    
    var body: some View {
        ZStack(alignment: Alignment.bottomTrailing) {
            PageViewController(currentPage: $views.currentPage)
            HStack {
                Spacer();
                if (colorScheme == .light) {
                    PageControl(numberOfPages: $views.pages, currentPage: $views.currentPage, colorScheme: .light)
                } else {
                    PageControl(numberOfPages: $views.pages, currentPage: $views.currentPage, colorScheme: .dark)
                }
                Spacer();
            }
        }
    }
}

struct SearchView: View {
    @EnvironmentObject var contacts: Contacts
    
    var body: some View {
        NavigationView {
            MasterView(contacts: $contacts.contacts)
                .navigationBarTitle(Text("Search"))
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button(
                        action: {
                            views.views.append(UIHostingController(rootView: EditView(selectedContact: new())))
                            views.currentPage = views.pages
                            views.pages += 1
                            //withAnimation {  }
                        }
                    ) {
                        Image(systemName: "plus")
                    }
            )
            DetailView()
        }
    }
}

struct MasterView: View {
    @Binding var contacts: [CNMutableContact]
    @State var search: String = ""

    var body: some View {
        VStack {
            SearchBar(text: $search)
        List {
            ForEach(contacts, id: \.self) { contact in
                NavigationLink(
                    destination: DetailView(selectedContact: contact)
                ) {
                    Text(name(contact))
                }
            }.onDelete { indices in
                delete(at: indices)
            }
        }
        }
    }
}

struct DetailView: View {
    var selectedContact: CNMutableContact?

    var body: some View {
        Group {
            Text(name(selectedContact))
        }.navigationBarTitle(Text(name(selectedContact)))
    }
}


struct EditView: View {
    var selectedContact: CNMutableContact

    var body: some View {
        NavigationView {
            Text(name(selectedContact)).navigationBarTitle(Text(name(selectedContact))).navigationBarItems(
                leading: Button(
                    action: {
                        views.currentPage -= 1
                        views.views.remove(at: views.currentPage + 1)
                        views.pages -= 1
                    }
                ) {
                    Text("Done")
                },
                trailing: Button(
                    action: {
                        views.views.append(UIHostingController(rootView: EditView(selectedContact: new())))
                        views.currentPage = views.pages
                        views.pages += 1
                        //withAnimation {  }
                    }
                ) {
                    Image(systemName: "plus")
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(views)
    }
}
