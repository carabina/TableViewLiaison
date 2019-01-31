//
//  TableViewRow.swift
//  TableViewLiaison
//
//  Created by Dylan Shine on 3/15/18.
//  Copyright © 2018 Dylan Shine. All rights reserved.
//

import UIKit

open class TableViewRow<Cell: UITableViewCell, Model>: AnyTableViewRow {
    
    public let model: Model
    public var editingStyle: UITableViewCell.EditingStyle
    public var movable: Bool
    public var editActions: [UITableViewRowAction]?
    public var indentWhileEditing: Bool
    public var deleteConfirmationTitle: String?
    public var deleteRowAnimation: UITableView.RowAnimation
    
    private let registrationType: TableViewRegistrationType<Cell>
    private var commands = [TableViewRowCommand: (Cell, Model, IndexPath) -> Void]()
    private var heights = [TableViewHeightType: (Model) -> CGFloat]()
    private var prefetchCommands = [TableViewPrefetchCommand: (Model, IndexPath) -> Void]()
    
    public init(_ model: Model,
                editingStyle: UITableViewCell.EditingStyle = .none,
                movable: Bool = false,
                editActions: [UITableViewRowAction]? = nil,
                indentWhileEditing: Bool = false,
                deleteConfirmationTitle: String? = nil,
                deleteRowAnimation: UITableView.RowAnimation = .automatic,
                registrationType: TableViewRegistrationType<Cell> = .defaultClassType) {
        self.model = model
        self.editingStyle = editingStyle
        self.movable = movable
        self.editActions = editActions
        self.indentWhileEditing = indentWhileEditing
        self.deleteConfirmationTitle = deleteConfirmationTitle
        self.deleteRowAnimation = deleteRowAnimation
        self.registrationType = registrationType
    }
    
    // MARK: - Cell
    public func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(Cell.self, with: reuseIdentifier)
        commands[.configuration]?(cell, model, indexPath)
        return cell
    }
    
    public func register(with tableView: UITableView) {
        switch registrationType {
        case let .class(identifier):
            tableView.register(Cell.self, with: identifier)
        case let .nib(nib, identifier):
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
    }
    
    // MARK: - Commands
    public func perform(command: TableViewRowCommand, for cell: UITableViewCell, at indexPath: IndexPath) {
        
        guard let cell = cell as? Cell else { return }
        
        commands[command]?(cell, model, indexPath)
    }
    
    public func perform(prefetchCommand: TableViewPrefetchCommand, for indexPath: IndexPath) {
        prefetchCommands[prefetchCommand]?(model, indexPath)
    }
    
    public func set(command: TableViewRowCommand, with closure: @escaping (Cell, Model, IndexPath) -> Void) {
        commands[command] = closure
    }
    
    public func remove(command: TableViewRowCommand) {
        commands[command] = nil
    }
    
    public func set(height: TableViewHeightType, _ closure: @escaping (Model) -> CGFloat) {
        heights[height] = closure
    }
    
    public func set(height: TableViewHeightType, _ value: CGFloat) {
        let closure: ((Model) -> CGFloat) = { _ -> CGFloat in return value }
        heights[height] = closure
    }
    
    public func remove(height: TableViewHeightType) {
        heights[height] = nil
    }
    
    public func set(prefetchCommand: TableViewPrefetchCommand, with closure: @escaping (Model, IndexPath) -> Void) {
        prefetchCommands[prefetchCommand] = closure
    }
    
    public func remove(prefetchCommand: TableViewPrefetchCommand) {
        prefetchCommands[prefetchCommand] = nil
    }
    
    // MARK: - Computed Properties
    public var height: CGFloat {
        return calculate(height: .height)
    }
    
    public var estimatedHeight: CGFloat {
        return calculate(height: .estimatedHeight)
    }
    
    public var editable: Bool {
        return editingStyle != .none || editActions?.isEmpty == false
    }
    
    public var reuseIdentifier: String {
        return registrationType.reuseIdentifier
    }

    // MARK: - Private
    
    private func calculate(height: TableViewHeightType) -> CGFloat {
        return heights[height]?(model) ?? UITableView.automaticDimension
    }
}

public extension TableViewRow where Model == Void {
    
    public convenience init(editingStyle: UITableViewCell.EditingStyle = .none,
                            movable: Bool = false,
                            editActions: [UITableViewRowAction]? = nil,
                            indentWhileEditing: Bool = false,
                            deleteConfirmationTitle: String? = nil,
                            deleteRowAnimation: UITableView.RowAnimation = .automatic,
                            registrationType: TableViewRegistrationType<Cell> = .defaultClassType) {
        
        self.init((),
                  editingStyle: editingStyle,
                  movable: movable,
                  editActions: editActions,
                  indentWhileEditing: indentWhileEditing,
                  deleteConfirmationTitle: deleteConfirmationTitle,
                  deleteRowAnimation: deleteRowAnimation,
                  registrationType: registrationType)
    }
}