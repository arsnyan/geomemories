//
//  CreateEditEntryPresenter.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

protocol CreateEditEntryPresentationLogic {
    func presentNavigationBarTitle(response: CreateEditEntry.ConfigurePurpose.Response)
    func presentInitialValues(response: CreateEditEntry.ConfigureInitial.Response)
    func unpresentCurrentView()
}

class CreateEditEntryPresenter: CreateEditEntryPresentationLogic {
    weak var viewController: CreateEditEntryDisplayLogic?
    
    func presentNavigationBarTitle(
        response: CreateEditEntry.ConfigurePurpose.Response
    ) {
        let editingTitle = String(localized: "editingTitle")
        let creatingTitle = String(localized: "creatingTitle")
        let title = response.isEditMode ? editingTitle : creatingTitle
        
        let viewModel = CreateEditEntry.ConfigurePurpose.ViewModel(title: title)
        viewController?.configureNavigationBarTitle(viewModel: viewModel)
    }
    
    func presentInitialValues(response: CreateEditEntry.ConfigureInitial.Response) {
        viewController?.setInitialTexts(
            viewModel: .init(
                title: response.title,
                description: response.description
            )
        )
    }
    
    func unpresentCurrentView() {
        viewController?.dismissView()
    }
}
