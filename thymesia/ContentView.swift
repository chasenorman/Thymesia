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
    @Published var views: [UIViewController] = [UIHostingController(rootView: SearchView().environmentObject(contacts))];
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
    return c;
}

func name(_ contact: CNMutableContact) -> String {
    return nameFormatter.string(from: contact) ?? "No Name"
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
    @State private var currentPage = 0
    @EnvironmentObject var views: Views;
    
    var body: some View {
        ZStack(alignment: Alignment.bottomTrailing) {
            PageViewController(controllers: views.views, currentPage: $currentPage)
            HStack {
                Spacer();
                PageControl(numberOfPages: views.views.count, currentPage: $currentPage)
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
                .navigationBarTitle(Text("Master"))
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button(
                        action: {
                            //withAnimation { views.insert(UIHostingController(EditView())) }
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                )
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct MasterView: View {
    @Binding var contacts: [CNMutableContact]

    var body: some View {
        List {
            ForEach(contacts, id: \.self) { contact in
                NavigationLink(
                    destination: DetailView(selectedContact: contact)
                ) {
                    Text(name(contact))
                }
            }.onDelete { indices in
                indices.forEach { self.contacts.remove(at: $0) }
            }
        }
    }
}

struct DetailView: View {
    var selectedContact: CNMutableContact?

    var body: some View {
        Group {
            if selectedContact != nil {
                Text(name(selectedContact!))
            } else {
                Text("Detail view content goes here")
            }
        }.navigationBarTitle(Text("Detail"))
    }
}


struct EditView: View {
    var selectedContact: CNMutableContact

    var body: some View {
        Group {
            Text(name(selectedContact))
        }.navigationBarTitle(Text("Edit"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
