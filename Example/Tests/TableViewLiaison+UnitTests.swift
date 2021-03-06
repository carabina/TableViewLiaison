//
//  TableViewLiaison+UnitTests.swift
//  TableViewLiaisonTests
//
//  Created by Dylan Shine on 3/23/18.
//  Copyright © 2018 Dylan Shine. All rights reserved.
//

import XCTest
@testable import TableViewLiaison

final class OKTableViewLiaison_UnitTests: XCTestCase {
    var liaison: TableViewLiaison!
    var tableView: UITableView!

    override func setUp() {
        super.setUp()
        liaison = TableViewLiaison()
        tableView = UITableView()
        liaison.liaise(tableView: tableView)
    }

    func test_tableViewRetain_doesNotStronglyReferenceTableView() {
        let tableView = UITableView()
        let initial = CFGetRetainCount(tableView)
        liaison.liaise(tableView: tableView)
        let current = CFGetRetainCount(tableView)

        XCTAssertEqual(initial, current)
    }

    func test_paginationDelegateRetain_doesNotStronglyReferencePaginationDelegate() {
        let delegate = TestTableViewLiaisonPaginationDelegate()
        let initial = CFGetRetainCount(delegate)
        liaison.paginationDelegate = delegate
        let current = CFGetRetainCount(delegate)

        XCTAssertEqual(initial, current)
    }

    func test_liaise_setsDelegateAndDataSource() {
        XCTAssert(tableView.delegate === liaison)
        XCTAssert(tableView.dataSource === liaison)
        if #available(iOS 10.0, *) {
            XCTAssert(tableView.prefetchDataSource === liaison)
        }
        XCTAssert(liaison.tableView == tableView)
    }
    
    func test_detach_removesDelegateAndDataSource() {
        liaison.detach()
        XCTAssert(tableView.delegate == nil)
        XCTAssert(tableView.dataSource == nil)
        if #available(iOS 10.0, *) {
            XCTAssert(tableView.prefetchDataSource == nil)
        }
        XCTAssert(liaison.tableView == nil)
    }

    func test_toggleIsEditing_togglesTableViewEditingMode() {
        tableView.isEditing = true
        liaison.toggleIsEditing()

        XCTAssertFalse(tableView.isEditing)
    }

    func test_init_initializesWithSections() {
        let sections = [TableViewSection(), TableViewSection()]
        let liaison = TableViewLiaison(sections: sections)
        liaison.liaise(tableView: tableView)
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(liaison.sections.count, 2)
    }

    func test_appendSection_addsSectionToTableView() {
        XCTAssertEqual(tableView.numberOfSections, 0)

        let section = TableViewSection()
        liaison.append(section: section)

        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(liaison.sections.count, 1)
    }

    func test_appendSections_addsSectionsToTableView() {
        XCTAssertEqual(tableView.numberOfSections, 0)

        let section1 = TableViewSection()
        let section2 = TableViewSection()

        liaison.append(sections: [section1, section2])

        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(liaison.sections.count, 2)
    }

    func test_insertSection_insertsSectionIntoTableView() {
        let section1 = TableViewSection()
        liaison.append(section: section1)
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(liaison.sections.count, 1)

        let section2 = TableViewSection()
        liaison.insert(section: section2, at: 0)

        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(liaison.sections.count, 2)
    }

    func test_insertSections_insertsSectionsIntoTableView() {
        let section1 = TableViewSection()
        let section2 = TableViewSection()
        let section3 = TableViewSection()
        let section4 = TableViewSection()
        liaison.append(sections: [section1, section2])

        liaison.insert(sections: [section3, section4], startingAt: 1)

        XCTAssertEqual(tableView.numberOfSections, 4)
        XCTAssertEqual(liaison.sections.count, 4)
    }

    func test_deleteSection_removesSectionFromTableView() {
        let section1 = TableViewSection()
        let section2 = TableViewSection()

        liaison.append(sections: [section1, section2])

        liaison.deleteSection(at: 0)

        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(liaison.sections.count, 1)
    }
    
    func test_emptySection_removesAllRowsFromSection() {
        let section = TableViewSection(rows: [TestTableViewRow()])
        liaison.append(section: section)
        
        liaison.emptySection(at: 0)
        
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 0)
    }

    func test_replaceSection_replacesSectionOfTableView() {
        let row = TestTableViewRow()
        let section1 = TableViewSection(rows: [row])
        let section2 = TableViewSection(rows: [row, row])

        liaison.append(section: section1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)

        liaison.replaceSection(at: 0, with: section2)
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(liaison.sections.count, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
    }
    
    func test_moveSection_moveSectionOfTableView() {
        let row = TestTableViewRow()

        let section1 = TableViewSection(rows: [row])
        let section2 = TableViewSection(rows: [row, row])
        let section3 = TableViewSection(rows: [row, row, row])

        liaison.append(sections: [section1, section2, section3])

        liaison.moveSection(at: 0, to: 2)

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 2), 1)
    }

    func test_reloadSection_reloadsSectionOfTableView() {

        let header = TestTableViewSectionComponent()
        header.set(height: .estimatedHeight, 15)
        var capturedHeader: UITableViewHeaderFooterView?

        let string = "Test"
        header.set(command: .configuration) { view, _, _ in
            view.accessibilityIdentifier = string
            capturedHeader = view
        }

        let section = TableViewSection(componentDisplayOption: .header(component: header))
        
        liaison.append(section: section)
        liaison.reloadData()
        
        capturedHeader?.accessibilityIdentifier = "Changed"

        liaison.reloadSection(at: 0)
        
        XCTAssertEqual(capturedHeader?.accessibilityIdentifier, string)
    }
    
    func test_clearSections_removesAllSectionsFromTableView() {

        let section1 = TableViewSection()
        let section2 = TableViewSection()
        let section3 = TableViewSection()

        liaison.append(sections: [section1, section2, section3])
        liaison.clearSections()

        XCTAssertEqual(tableView.numberOfSections, 0)
        XCTAssertEqual(liaison.sections.count, 0)
    }

    func test_clearSections_removesAllSectionsFromTableViewAndAppendsNewSections() {

        let section1 = TableViewSection()
        let section2 = TableViewSection()
        let section3 = TableViewSection()
        let section4 = TableViewSection()
        let section5 = TableViewSection()

        liaison.append(sections: [section1, section2, section3])
        liaison.clearSections(replacedBy: [section4, section5])

        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(liaison.sections.count, 2)
    }
    
    func test_swapSections_swapsSectionsOfTableView() {
        let section1 = TableViewSection(rows: [TestTableViewRow()])
        let section2 = TableViewSection()
        let section3 = TableViewSection()
        
        liaison.append(sections: [section1, section2, section3])
        
        liaison.swapSection(at: 0, with: 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 0)
        XCTAssertEqual(tableView.numberOfRows(inSection: 2), 1)
    }

    func test_appendRow_appendsRowToSection() {
        let section = TableViewSection()
        let row = TestTableViewRow()

        var inserted = false
        var actualIndexPath: IndexPath?
        let expectedIndexPath = IndexPath(row: 0, section: 0)
        row.set(command: .insert) { (_, _, indexPath) in
            inserted = true
            actualIndexPath = indexPath
        }

        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.append(row: row)
        }
        
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(liaison.sections.first?.rows.last === row)
        XCTAssertTrue(inserted)
        XCTAssertEqual(actualIndexPath, expectedIndexPath)
    }

    func test_appendRows_appendsRowsToSection() {
        let section = TableViewSection()
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()

        var insertedRow1 = false
        var actualIndexPathRow1: IndexPath?
        let expectedIndexPathRow1 = IndexPath(row: 0, section: 0)
        row1.set(command: .insert) { (_, _, indexPath) in
            insertedRow1 = true
            actualIndexPathRow1 = indexPath
        }

        var insertedRow2 = false
        var actualIndexPathRow2: IndexPath?
        let expectedIndexPathRow2 = IndexPath(row: 1, section: 0)
        row2.set(command: .insert) { (_, _, indexPath) in
            insertedRow2 = true
            actualIndexPathRow2 = indexPath
        }

        liaison.append(section: section)

        XCTAssert(section.rows.count == 0)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.append(rows: [row1, row2])
        }

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
        XCTAssert(liaison.sections.first?.rows.first === row1)
        XCTAssert(liaison.sections.first?.rows.last === row2)
        XCTAssertTrue(insertedRow1)
        XCTAssertTrue(insertedRow2)
        XCTAssertEqual(actualIndexPathRow1, expectedIndexPathRow1)
        XCTAssertEqual(actualIndexPathRow2, expectedIndexPathRow2)
    }

    func test_insertRow_insertsRowIntoSection() {

        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2])

        liaison.append(section: section)

        let expectedIndexPath = IndexPath(row: 0, section: 0)
        var insertedRow = false
        var actualIndexPathRow: IndexPath?

        row3.set(command: .insert) { (_, _, indexPath) in
            insertedRow = true
            actualIndexPathRow = indexPath
        }

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.insert(row: row3, at: expectedIndexPath)
        }

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 3)
        XCTAssert(liaison.sections.first?.rows.first === row3)
        XCTAssertTrue(insertedRow)
        XCTAssertEqual(actualIndexPathRow, expectedIndexPath)
    }

    func test_deleteRows_removesRowsFromTableView() {
        let section1 = TableViewSection()
        let section2 = TableViewSection()
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        let row1IndexPath = IndexPath(row: 0, section: 0)
        var deletedRow1 = false
        var actualIndexPathRow1: IndexPath?
        row1.set(command: .delete) { (_, _, indexPath) in
            deletedRow1 = true
            actualIndexPathRow1 = indexPath
        }
        
        let row2IndexPath = IndexPath(row: 1, section: 0)
        var deletedRow2 = false
        var actualIndexPathRow2: IndexPath?
        row2.set(command: .delete) { (_, _, indexPath) in
            deletedRow2 = true
            actualIndexPathRow2 = indexPath
        }

        let row3IndexPath = IndexPath(row: 0, section: 1)
        var deletedRow3 = false
        var actualIndexPathRow3: IndexPath?
        row3.set(command: .delete) { (_, _, indexPath) in
            deletedRow3 = true
            actualIndexPathRow3 = indexPath
        }

        liaison.append(sections: [section1, section2])
        liaison.append(rows: [row1, row2])
        liaison.append(row: row3, to: 1)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.deleteRows(at: [row1IndexPath, row2IndexPath, row3IndexPath])
        }

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 0)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 0)
        XCTAssertTrue(deletedRow1)
        XCTAssertTrue(deletedRow2)
        XCTAssertTrue(deletedRow3)
        XCTAssertEqual(actualIndexPathRow1, row1IndexPath)
        XCTAssertEqual(actualIndexPathRow2, row2IndexPath)
        XCTAssertEqual(actualIndexPathRow3, row3IndexPath)
    }

    func test_deleteRow_removesRowFromSection() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()

        let expectedIndexPath = IndexPath(row: 0, section: 0)
        var deletedRow = false
        var actualIndexPathRow: IndexPath?
        row1.set(command: .delete) { (_, _, indexPath) in
            deletedRow = true
            actualIndexPathRow = indexPath
        }

        let section = TableViewSection(rows: [row1, row2])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.deleteRow(at: expectedIndexPath)
        }

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(liaison.sections.first?.rows.last === row2)
        XCTAssertTrue(deletedRow)
        XCTAssertEqual(actualIndexPathRow, expectedIndexPath)
    }

    func test_reloadRows_reloadsRowsInSection() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()

        var reloaded1 = false
        var reloaded2 = false

        row1.set(command: .reload) { (_, _, _) in
            reloaded1 = true
        }
        
        row2.set(command: .reload) { (_, _, _) in
            reloaded2 = true
        }

        let section = TableViewSection(rows: [row1, row2])

        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.reloadRows(at: [IndexPath(row: 0, section: 0), IndexPath(row: 1, section: 0)])
        }

        let count = tableView.callCounts[.reloadRows]

        XCTAssertEqual(count, 1)
        XCTAssertTrue(reloaded1)
        XCTAssertTrue(reloaded2)
    }
    
    func test_reloadRow_reloadsRowInSection() {
        let row = TestTableViewRow()
        
        var reloaded = false
        row.set(command: .reload) { (_, _, _) in
            reloaded = true
        }
        
        let section = TableViewSection(rows: [row])
        
        liaison.append(section: section)
        
        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.reloadRow(at: IndexPath(row: 0, section: 0))
        }
        
        let count = tableView.callCounts[.reloadRows]
        
        XCTAssertEqual(count, 1)
        XCTAssertTrue(reloaded)
    }

    func test_replaceRow_replaceRowInSection() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
    
        var deleted = false
        row1.set(command: .delete) { (_, _, _) in
            deleted = true
        }

        var inserted = false
        row2.set(command: .insert) { (_, _, _) in
            inserted = true
        }

        let section = TableViewSection(rows: [row1])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.replaceRow(at: IndexPath(row: 0, section: 0), with: row2)
        }

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(liaison.sections.first?.rows.first === row2)
        XCTAssertTrue(deleted)
        XCTAssertTrue(inserted)

    }

    func test_moveRow_withinSameSection() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        var moved = false
        var actualDestination: IndexPath?
        let destination = IndexPath(row: 2, section: 0)
        row1.set(command: .move) { (_, _, indexPath) in
            moved = true
            actualDestination = indexPath
        }

        let section = TableViewSection(rows: [row1, row2, row3])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.moveRow(from: IndexPath(row: 0, section: 0), to: destination)
        }
        
        XCTAssert(liaison.sections.first?.rows.first === row2)
        XCTAssert(liaison.sections.first?.rows.last === row1)
        XCTAssertTrue(moved)
        XCTAssertEqual(actualDestination, destination)

    }

    func test_moveRow_intoDifferentSection() {
        let section1 = TableViewSection()
        let section2 = TableViewSection()

        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()
        let row4 = TestTableViewRow()
        let row5 = TestTableViewRow()

        var moved = false
        var actualDestination: IndexPath?
        let destination = IndexPath(row: 2, section: 1)
        row1.set(command: .move) { (_, _, indexPath) in
            moved = true
            actualDestination = indexPath
        }

        liaison.append(section: section1)
        liaison.append(section: section2)

        liaison.append(rows: [row1, row2, row3])
        liaison.append(rows: [row4, row5], to: 1)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.moveRow(from: IndexPath(row: 0, section: 0), to: destination)
        }

        XCTAssertEqual(liaison.sections.first?.rows.count, 2)
        XCTAssert(liaison.sections.first?.rows.first === row2)
        XCTAssertEqual(liaison.sections.last?.rows.count, 3)
        XCTAssert(liaison.sections.last?.rows.last === row1)
        XCTAssertTrue(moved)
        XCTAssertEqual(actualDestination, destination)
    }

    func test_swapRow_withinSameSection() {
        let section = TableViewSection()
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        var sourceMoved = false
        var swappedSourceIndexPath: IndexPath?
        let sourceIndexPath = IndexPath(row: 0, section: 0)
        row1.set(command: .move) { (_, _, indexPath) in
            sourceMoved = true
            swappedSourceIndexPath = indexPath
        }

        var destinationMoved = false
        var swappedDestinationIndexPath: IndexPath?
        let destinationIndexPath = IndexPath(row: 2, section: 0)
        row3.set(command: .move) { (_, _, indexPath) in
            destinationMoved = true
            swappedDestinationIndexPath = indexPath
        }

        liaison.append(section: section)
        liaison.append(rows: [row1, row2, row3])

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.swapRow(at: sourceIndexPath, with: destinationIndexPath)
        }
        
        XCTAssert(liaison.sections.first?.rows.first === row3)
        XCTAssert(liaison.sections.first?.rows.last === row1)
        XCTAssertTrue(sourceMoved)
        XCTAssertTrue(destinationMoved)
        XCTAssertEqual(swappedSourceIndexPath, destinationIndexPath)
        XCTAssertEqual(swappedDestinationIndexPath, sourceIndexPath)

    }

    func test_swapRow_intoDifferentSection() {
        let section1 = TableViewSection()
        let section2 = TableViewSection()

        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()
        let row4 = TestTableViewRow()

        var sourceMoved = false
        var swappedSourceIndexPath: IndexPath?
        let sourceIndexPath = IndexPath(row: 0, section: 0)
        row1.set(command: .move) { (_, _, indexPath) in
            sourceMoved = true
            swappedSourceIndexPath = indexPath
        }

        var destinationMoved = false
        var swappedDestinationIndexPath: IndexPath?
        let destinationIndexPath = IndexPath(row: 1, section: 1)
        row4.set(command: .move) { (_, _, indexPath) in
            destinationMoved = true
            swappedDestinationIndexPath = indexPath
        }

        liaison.append(section: section1)
        liaison.append(section: section2)

        liaison.append(rows: [row1, row2])
        liaison.append(rows: [row3, row4], to: 1)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.swapRow(at: sourceIndexPath, with: destinationIndexPath)
        }
        
        XCTAssert(liaison.sections.first?.rows.first === row4)
        XCTAssert(liaison.sections.last?.rows.last === row1)
        XCTAssertTrue(sourceMoved)
        XCTAssertTrue(destinationMoved)
        XCTAssertEqual(swappedSourceIndexPath, destinationIndexPath)
        XCTAssertEqual(swappedDestinationIndexPath, sourceIndexPath)
    }

    func test_tableViewCellForRow_createsCorrectCellForRow() {
        let section = TableViewSection()

        let row = TestTableViewRow()
        let string = "Test"
        row.set(command: .configuration) { (cell, _, indexPath) in
            cell.accessibilityIdentifier = string
        }

        liaison.append(section: section)
        liaison.append(row: row)

        let cell = liaison.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        XCTAssertEqual(cell.accessibilityIdentifier, string)

    }

    func test_numberOfSectionsInTableView_returnsCorrectAmountOfSections() {
        let section1 = TableViewSection()
        let section2 = TableViewSection()

        liaison.append(sections: [section1, section2])
        let count = liaison.numberOfSections(in: tableView)

        XCTAssertEqual(count, 2)
    }

    func test_tableViewNumberOfRowsInSection_returnsCorrectAmountOfRows() {

        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()
        let row4 = TestTableViewRow()
        let row5 = TestTableViewRow()

        let section1 = TableViewSection(rows: [row1, row2])
        let section2 = TableViewSection(rows: [row3, row4, row5])

        liaison.append(section: section1)
        liaison.append(section: section2)

        let section1Count = liaison.tableView(tableView, numberOfRowsInSection: 0)
        let section2Count = liaison.tableView(tableView, numberOfRowsInSection: 1)

        XCTAssertEqual(section1Count, 2)
        XCTAssertEqual(section2Count, 3)
    }

    func test_tableViewCanEditRow_correctlyReturnsWhetherRowIsEditable() {
        let row1 = TestTableViewRow(editingStyle: .delete)
        let row2 = TestTableViewRow(editingStyle: .insert)
        let row3 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2, row3])
        liaison.append(section: section)

        let row1Editable = liaison.tableView(tableView, canEditRowAt: IndexPath(row: 0, section: 0))
        let row2Editable = liaison.tableView(tableView, canEditRowAt: IndexPath(row: 1, section: 0))
        let row3Editable = liaison.tableView(tableView, canEditRowAt: IndexPath(row: 2, section: 0))
        let nonExistentRowEditable = liaison.tableView(tableView, canEditRowAt: IndexPath(row: 3, section: 0))

        XCTAssertTrue(row1Editable)
        XCTAssertTrue(row2Editable)
        XCTAssertFalse(row3Editable)
        XCTAssertFalse(nonExistentRowEditable)
    }

    func test_tableViewCanMoveRow_correctlyReturnsWhetherRowIsMovable() {
        let row1 = TestTableViewRow(movable: true)
        let row2 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2])
        liaison.append(section: section)

        let row1Movable = liaison.tableView(tableView, canMoveRowAt: IndexPath(row: 0, section: 0))
        let row2Movable = liaison.tableView(tableView, canMoveRowAt: IndexPath(row: 1, section: 0))
        let nonExistentRowMovable = liaison.tableView(tableView, canMoveRowAt: IndexPath(row: 2, section: 0))

        XCTAssertTrue(row1Movable)
        XCTAssertFalse(row2Movable)
        XCTAssertFalse(nonExistentRowMovable)
    }

    func test_tableViewCommitEditingStyle_performsEditingActionRowForIndexPath() {
        let section = TableViewSection()
        let row1 = TestTableViewRow(editingStyle: .delete)
        let row2 = TestTableViewRow(editingStyle: .insert)
        var deleted = false
        var inserted = false

        row1.set(command: .delete) { _, _, _ in
            deleted = true
        }

        row2.set(command: .insert) { _, _, _ in
            inserted = true
        }

        liaison.append(section: section)
        liaison.append(rows: [row1, row2])

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, commit: .delete, forRowAt: IndexPath(row: 0, section: 0))
            liaison.tableView(tableView, commit: .insert, forRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(deleted)
        XCTAssertTrue(inserted)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(liaison.sections.first?.rows.count, 1)
    }

    func test_moveRowAt_properlyMovesRowFromOneSourceIndexPathToDestinationIndexPath() {

        var moved = false
        let row1 = TestTableViewRow()
        row1.set(command: .move) { (_, _, _) in
            moved = true
        }

        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        let section1 = TableViewSection(rows: [row1, row2, row3])
        let section2 = TableViewSection()

        liaison.append(sections: [section1, section2])

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, moveRowAt: IndexPath(row: 0, section: 0), to: IndexPath(row: 0, section: 1))
        }

        XCTAssertTrue(moved)
        XCTAssertEqual(liaison.sections.first?.rows.count, 2)
        XCTAssert(liaison.sections.last?.rows.first === row1)
    }

    func test_willSelectRow_performsWillSelectCommand() {

        let row = TestTableViewRow()
        var willSelect = false

        row.set(command: .willSelect) { _, _, _ in
            willSelect = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        let expectedIndexPath = IndexPath(row: 0, section: 0)
        var indexPath: IndexPath?
        tableView.performInSwizzledEnvironment {
           indexPath = liaison.tableView(tableView, willSelectRowAt: expectedIndexPath)
        }

        XCTAssertTrue(willSelect)
        XCTAssertEqual(indexPath, expectedIndexPath)
    }

    func test_didSelectRow_performsDidSelectCommand() {
        let row = TestTableViewRow()
        var didSelected = false

        row.set(command: .didSelect) { _, _, _ in
            didSelected = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(didSelected)
    }

    func test_willDeselectRow_performsWillDeselectCommand() {
        let row = TestTableViewRow()
        var willDeselect = false

        row.set(command: .willDeselect) { _, _, _ in
            willDeselect = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        let expectedIndexPath = IndexPath(row: 0, section: 0)
        var indexPath: IndexPath?
        tableView.performInSwizzledEnvironment {
            indexPath = liaison.tableView(tableView, willDeselectRowAt: expectedIndexPath)
        }

        XCTAssertTrue(willDeselect)
        XCTAssertEqual(indexPath, expectedIndexPath)
    }

    func test_didDeselectRow_performsDidDeselectCommand() {
        let row = TestTableViewRow()
        var didDeselect = false

        row.set(command: .didDeselect) { (_, _, _) in
            didDeselect = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, didDeselectRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(didDeselect)
    }

    func test_targetIndexPathForMoveFromRowToProposed_correctlyMovesRow() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()
        let row4 = TestTableViewRow()
        let row5 = TestTableViewRow()

        let section1 = TableViewSection(rows: [row1, row2, row3])
        let section2 = TableViewSection(rows: [row4, row5])

        liaison.append(sections: [section1, section2])

        let destination = liaison.tableView(tableView,
                                            targetIndexPathForMoveFromRowAt: IndexPath(row: 0, section: 0),
                                            toProposedIndexPath: IndexPath(row: 0, section: 1))
        
        XCTAssertEqual(liaison.sections.first?.rows.count, 2)
        XCTAssertEqual(liaison.sections.last?.rows.count, 3)

        XCTAssert(liaison.sections.first?.rows.first === row2)
        XCTAssert(liaison.sections.last?.rows.first === row1)
        XCTAssertEqual(destination, IndexPath(row: 0, section: 1))
    }

    func test_willDisplayCell_performsWillDisplayCommand() {
        let row = TestTableViewRow()
        var willDisplay = false

        row.set(command: .willDisplay) { (_, _, _) in
            willDisplay = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        let cell = UITableViewCell()
        liaison.tableView(tableView, willDisplay: cell, forRowAt: IndexPath(row: 0, section: 0))

        XCTAssertTrue(willDisplay)
    }

    func test_willDisplayCell_paginationDelegateGetsCalled() {
        
        let delegate = TestTableViewLiaisonPaginationDelegate()
        liaison.paginationDelegate = delegate

        let section = TableViewSection(rows: [TestTableViewRow()])
        liaison.append(section: section)

        liaison.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 0, section: 0))

        keyValueObservingExpectation(for: delegate, keyPath: "paginationStartedCallCount") { (delegate, json) -> Bool in
            guard let delegate = delegate as? TestTableViewLiaisonPaginationDelegate else {
                return false
            }

            return delegate.paginationStartedCallCount == 1 && delegate.isPaginationEnabledCallCount == 1
        }

        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func test_willDisplayCell_appendsPaginationSection() {
        let delegate = TestTableViewLiaisonPaginationDelegate()
        liaison.paginationDelegate = delegate
        
        let section = TableViewSection(rows: [TestTableViewRow()])
        liaison.append(section: section)
        
        let expectation = XCTestExpectation(description: "Adds pagination section")
        
        liaison.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 0, section: 0))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssert(self.liaison.sections.last?.rows.first === self.liaison.paginationSection.rows.first)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }

    func test_appendSection_paginationDelegateEndsByAppendingSection() {
        let section1 = TableViewSection(rows: [TestTableViewRow(), TestTableViewRow()])
        let delegate = TestTableViewLiaisonPaginationDelegate()
        let section2 = TableViewSection(rows: [TestTableViewRow()])

        liaison.paginationDelegate = delegate
        liaison.append(section: section1)
        liaison.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 1, section: 0))

        DispatchQueue.main.async {
            self.liaison.append(section: section2)
        }

        keyValueObservingExpectation(for: delegate, keyPath: "paginationEndedCallCount") { (delegate, json) -> Bool in
            guard let delegate = delegate as? TestTableViewLiaisonPaginationDelegate else {
                return false
            }

            return delegate.paginationEndedCallCount == 1
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func test_appendRow_paginationDelegateEndsByAppendingRow() {
        let section = TableViewSection(rows: [TestTableViewRow()])
        let delegate = TestTableViewLiaisonPaginationDelegate()
        let row2 = TestTableViewRow()

        liaison.paginationDelegate = delegate
        liaison.append(section: section)

        liaison.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 0, section: 0))

        DispatchQueue.main.async {
            self.liaison.append(row: row2)
        }

        keyValueObservingExpectation(for: delegate, keyPath: "paginationEndedCallCount") { (delegate, json) -> Bool in
            guard let delegate = delegate as? TestTableViewLiaisonPaginationDelegate else {
                return false
            }

            return delegate.paginationEndedCallCount == 1
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func test_didEndDisplayingCell_performsDidEndDisplayingCommand() {
        let row = TestTableViewRow()
        var didEndDisplaying = false

        row.set(command: .didEndDisplaying) { (_, _, _) in
            didEndDisplaying = true
        }

        liaison.append(section: TableViewSection(rows: [row]))

        let cell = UITableViewCell()
        liaison.tableView(tableView, didEndDisplaying: cell, forRowAt: IndexPath(row: 0, section: 0))

        XCTAssertTrue(didEndDisplaying)
    }

    func test_willBeginEditingRow_performsWillBeginEditingCommand() {
        let row = TestTableViewRow()
        var willBeginEditing = false

        row.set(command: .willBeginEditing) { (_, _, _) in
            willBeginEditing = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, willBeginEditingRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(willBeginEditing)
    }

    func test_didEndEditingRow_performsDidEndEditingCommand() {
        let row = TestTableViewRow()
        var didEndEditing = false

        row.set(command: .didEndEditing) { (_, _, _) in
            didEndEditing = true
        }

        liaison.append(section: TableViewSection(rows: [row]))

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, didEndEditingRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(didEndEditing)
    }

    func test_didHighlightRow_performsDidHighlightRowCommand() {
        let row = TestTableViewRow()
        var didHighlight = false

        row.set(command: .didHighlight) { (_, _, _) in
            didHighlight = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, didHighlightRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(didHighlight)
    }

    func test_didUnhighlightRow_performsDidUnhighlightRowCommand() {
        let row = TestTableViewRow()
        var didUnhighlight = false

        row.set(command: .didUnhighlight) { (_, _, _) in
            didUnhighlight = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, didUnhighlightRowAt: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(didUnhighlight)
    }

    func test_viewForHeaderInSection_returnCorrectHeaderForSection() {

        let header = TestTableViewSectionComponent()

        header.set(command: .configuration) { view, _, section in
            view.accessibilityIdentifier = "\(section)"
        }

        let section1 = TableViewSection(componentDisplayOption: .header(component: header))
        let section2 = TableViewSection(componentDisplayOption: .header(component: header))

        liaison.append(sections: [section1, section2])

        let section1Header = liaison.tableView(tableView, viewForHeaderInSection: 0)
        let section2Header = liaison.tableView(tableView, viewForHeaderInSection: 1)

        XCTAssertEqual(section1Header?.accessibilityIdentifier, "0")
        XCTAssertEqual(section2Header?.accessibilityIdentifier, "1")
    }

    func test_viewForFooterInSection_returnCorrectFooterForSection() {

        let footer = TestTableViewSectionComponent()

        footer.set(command: .configuration) { view, _, section in
            view.accessibilityIdentifier = "\(section)"
        }

        let section1 = TableViewSection(componentDisplayOption: .footer(component: footer))
        let section2 = TableViewSection(componentDisplayOption: .footer(component: footer))

        liaison.append(sections: [section1, section2])

        let section1Header = liaison.tableView(tableView, viewForFooterInSection: 0)
        let section2Header = liaison.tableView(tableView, viewForFooterInSection: 1)

        XCTAssertEqual(section1Header?.accessibilityIdentifier, "0")
        XCTAssertEqual(section2Header?.accessibilityIdentifier, "1")
    }

    func test_heightForRow_properlySetsHeightsForRows() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        row1.set(height: .height) { _ -> CGFloat in
            return 100
        }

        row2.set(height: .height, 200)

        let section = TableViewSection(rows: [row1, row2, row3])
        liaison.append(section: section)

        let row1Height = liaison.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: 0))
        let row2Height = liaison.tableView(tableView, heightForRowAt: IndexPath(row: 1, section: 0))
        let row3Height = liaison.tableView(tableView, heightForRowAt: IndexPath(row: 2, section: 0))

        XCTAssertEqual(row1Height, 100)
        XCTAssertEqual(row2Height, 200)
        XCTAssertEqual(row3Height, UITableView.automaticDimension)
    }

    func test_estimatedHeightForRow_properlySetsEstimatedHeightsForRows() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        let row3 = TestTableViewRow()

        row1.set(height: .estimatedHeight) { _ -> CGFloat in
            return 100
        }

        row2.set(height: .estimatedHeight, 200)

        let section = TableViewSection(rows: [row1, row2, row3])
        liaison.append(section: section)

        let row1Height = liaison.tableView(tableView, estimatedHeightForRowAt: IndexPath(row: 0, section: 0))
        let row2Height = liaison.tableView(tableView, estimatedHeightForRowAt: IndexPath(row: 1, section: 0))
        let row3Height = liaison.tableView(tableView, estimatedHeightForRowAt: IndexPath(row: 2, section: 0))

        XCTAssertEqual(row1Height, 100)
        XCTAssertEqual(row2Height, 200)
        XCTAssertEqual(row3Height, UITableView.automaticDimension)
    }

    func test_shouldIndentWhileEditingRow_correctlyReturnsIfRowShouldIndentWhileBeingEdited() {
        let row1 = TestTableViewRow(indentWhileEditing: true)
        let row2 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2])
        liaison.append(section: section)

        let row1ShouldIndent = liaison.tableView(tableView, shouldIndentWhileEditingRowAt: IndexPath(row: 0, section: 0))
        let row2ShouldIndent = liaison.tableView(tableView, shouldIndentWhileEditingRowAt: IndexPath(row: 1, section: 0))
        let nonExistentRowShouldIndent = liaison.tableView(tableView, shouldIndentWhileEditingRowAt: IndexPath(row: 2, section: 0))

        XCTAssertTrue(row1ShouldIndent)
        XCTAssertFalse(row2ShouldIndent)
        XCTAssertFalse(nonExistentRowShouldIndent)
    }

    func test_editingStyleForRow_correctlyReturnsEditingStyleForRow() {
        let row1 = TestTableViewRow(editingStyle: .delete)
        let row2 = TestTableViewRow(editingStyle: .insert)
        let row3 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2, row3])
        liaison.append(section: section)

        let row1EditingStyle = liaison.tableView(tableView, editingStyleForRowAt: IndexPath(row: 0, section: 0))
        let row2EditingStyle = liaison.tableView(tableView, editingStyleForRowAt: IndexPath(row: 1, section: 0))
        let row3EditingStyle = liaison.tableView(tableView, editingStyleForRowAt: IndexPath(row: 2, section: 0))
        let nonExistentRowEditingStyle = liaison.tableView(tableView, editingStyleForRowAt: IndexPath(row: 3, section: 0))

        XCTAssertEqual(row1EditingStyle, .delete)
        XCTAssertEqual(row2EditingStyle, .insert)
        XCTAssertEqual(row3EditingStyle, .none)
        XCTAssertEqual(nonExistentRowEditingStyle, .none)
    }

    func test_editActionsForRow_correctlyReturnsEditActions() {
        let editAction = UITableViewRowAction(style: .normal, title: "Action", handler: { (action, indexPath) in
            print("This action is being invoked")
        })

        let row1 = TestTableViewRow(editActions: [editAction])
        let row2 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2])
        liaison.append(section: section)

        let row1EditActions = liaison.tableView(tableView, editActionsForRowAt: IndexPath(row: 0, section: 0))
        let row2EditActions = liaison.tableView(tableView, editActionsForRowAt: IndexPath(row: 1, section: 0))
        let nonExistentRowEditActions = liaison.tableView(tableView, editActionsForRowAt: IndexPath(row: 2, section: 0))
        XCTAssertEqual(row1EditActions?.first, editAction)
        XCTAssert(row2EditActions == nil)
        XCTAssert(nonExistentRowEditActions == nil)
    }

    func test_accessoryButtonTapped_performsAccessoryButtonTappedCommand() {
        let row = TestTableViewRow()
        var accessoryButtonTapped = false

        row.set(command: .accessoryButtonTapped) { (_, _, _) in
            accessoryButtonTapped = true
        }

        let section = TableViewSection(rows: [row])
        liaison.append(section: section)

        tableView.stubCell = UITableViewCell()
        tableView.performInSwizzledEnvironment {
            liaison.tableView(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 0, section: 0))
        }

        XCTAssertTrue(accessoryButtonTapped)
    }

    func test_titleForDeleteConfirmationButton_returnsCorrectDeleteConfirmationTitleForRow() {
        let row1 = TestTableViewRow(deleteConfirmationTitle: "Delete")
        let row2 = TestTableViewRow()

        let section = TableViewSection(rows: [row1, row2])
        liaison.append(section: section)

        let row1DeleteConfirmationTitle = liaison.tableView(tableView, titleForDeleteConfirmationButtonForRowAt: IndexPath(row: 0, section: 0))
        let row2DeleteConfirmationTitle = liaison.tableView(tableView, titleForDeleteConfirmationButtonForRowAt: IndexPath(row: 1, section: 0))
        let nonExistentRowDeleteConfirmationTitle = liaison.tableView(tableView, titleForDeleteConfirmationButtonForRowAt: IndexPath(row: 2, section: 0))

        XCTAssertEqual(row1DeleteConfirmationTitle, "Delete")
        XCTAssert(row2DeleteConfirmationTitle == nil)
        XCTAssert(nonExistentRowDeleteConfirmationTitle == nil)
    }

    func test_heightForHeader_properlySetsHeightsForSectionHeaders() {
        let header1 = TestTableViewSectionComponent()
        let header2 = TestTableViewSectionComponent()
        let header3 = TestTableViewSectionComponent()

        header1.set(height: .height, 100)

        header2.set(height: .height) { _ -> CGFloat in
            return 200
        }

        let section1 = TableViewSection(componentDisplayOption: .header(component: header1))
        let section2 = TableViewSection(componentDisplayOption: .header(component: header2))
        let section3 = TableViewSection(componentDisplayOption: .header(component: header3))

        liaison.append(sections: [section1, section2, section3])

        let section1Height = liaison.tableView(tableView, heightForHeaderInSection: 0)
        let section2Height = liaison.tableView(tableView, heightForHeaderInSection: 1)
        let section3Height = liaison.tableView(tableView, heightForHeaderInSection: 2)

        XCTAssertEqual(section1Height, 100)
        XCTAssertEqual(section2Height, 200)
        XCTAssertEqual(section3Height, UITableView.automaticDimension)
    }
    
    func test_estimatedHeightForHeader_properlySetsEstimatedHeightsForSectionHeaders() {
        let header1 = TestTableViewSectionComponent()
        let header2 = TestTableViewSectionComponent()
        let header3 = TestTableViewSectionComponent()
        let header4 = TestTableViewSectionComponent()
        
        header1.set(height: .estimatedHeight, 100)
        
        header2.set(height: .estimatedHeight) { _ -> CGFloat in
            return 200
        }
        
        header3.set(height: .height, 300)
        
        let section1 = TableViewSection(componentDisplayOption: .header(component: header1))
        let section2 = TableViewSection(componentDisplayOption: .header(component: header2))
        let section3 = TableViewSection(componentDisplayOption: .header(component: header3))
        let section4 = TableViewSection(componentDisplayOption: .header(component: header4))

        liaison.append(sections: [section1, section2, section3, section4])
        
        let section1EstimatedHeight = liaison.tableView(tableView, estimatedHeightForHeaderInSection: 0)
        let section2EstimatedHeight = liaison.tableView(tableView, estimatedHeightForHeaderInSection: 1)
        let section3EstimatedHeight = liaison.tableView(tableView, estimatedHeightForHeaderInSection: 2)
        let section4EstimatedHeight = liaison.tableView(tableView, estimatedHeightForHeaderInSection: 3)

        XCTAssertEqual(section1EstimatedHeight, 100)
        XCTAssertEqual(section2EstimatedHeight, 200)
        XCTAssertEqual(section3EstimatedHeight, 300)
        XCTAssertEqual(section4EstimatedHeight, 0)
    }

    func test_heightForFooter_properlySetsHeightsForSectionFooters() {
        let footer1 = TestTableViewSectionComponent()
        let footer2 = TestTableViewSectionComponent()
        let footer3 = TestTableViewSectionComponent()

        footer1.set(height: .height, 100)

        footer2.set(height: .height) { _ -> CGFloat in
            return 200
        }

        let section1 = TableViewSection(componentDisplayOption: .footer(component: footer1))
        let section2 = TableViewSection(componentDisplayOption: .footer(component: footer2))
        let section3 = TableViewSection(componentDisplayOption: .footer(component: footer3))

        liaison.append(sections: [section1, section2, section3])

        let section1Height = liaison.tableView(tableView, heightForFooterInSection: 0)
        let section2Height = liaison.tableView(tableView, heightForFooterInSection: 1)
        let section3Height = liaison.tableView(tableView, heightForFooterInSection: 2)

        XCTAssertEqual(section1Height, 100)
        XCTAssertEqual(section2Height, 200)
        XCTAssertEqual(section3Height, UITableView.automaticDimension)
    }
    
    func test_estimatedHeightForFooter_properlySetsEstimatedHeightsForSectionFooters() {
        let footer1 = TestTableViewSectionComponent()
        let footer2 = TestTableViewSectionComponent()
        let footer3 = TestTableViewSectionComponent()
        let footer4 = TestTableViewSectionComponent()
        
        footer1.set(height: .estimatedHeight, 100)
        
        footer2.set(height: .estimatedHeight) { _ -> CGFloat in
            return 200
        }
        
        footer3.set(height: .height, 300)
        
        let section1 = TableViewSection(componentDisplayOption: .footer(component: footer1))
        let section2 = TableViewSection(componentDisplayOption: .footer(component: footer2))
        let section3 = TableViewSection(componentDisplayOption: .footer(component: footer3))
        let section4 = TableViewSection(componentDisplayOption: .footer(component: footer4))
        
        liaison.append(sections: [section1, section2, section3, section4])
        
        let section1EstimatedHeight = liaison.tableView(tableView, estimatedHeightForFooterInSection: 0)
        let section2EstimatedHeight = liaison.tableView(tableView, estimatedHeightForFooterInSection: 1)
        let section3EstimatedHeight = liaison.tableView(tableView, estimatedHeightForFooterInSection: 2)
        let section4EstimatedHeight = liaison.tableView(tableView, estimatedHeightForFooterInSection: 3)

        XCTAssertEqual(section1EstimatedHeight, 100)
        XCTAssertEqual(section2EstimatedHeight, 200)
        XCTAssertEqual(section3EstimatedHeight, 300)
        XCTAssertEqual(section4EstimatedHeight, 0)
    }


    func test_willDisplayHeaderView_performsWillDisplayHeaderViewSectionCommand() {

        let header = TestTableViewSectionComponent()

        var willDisplay = false
        header.set(command: .willDisplay) { _, _, _ in
            willDisplay = true
        }

        let section = TableViewSection(componentDisplayOption: .header(component: header))

        liaison.append(section: section)
        let view = UITableViewHeaderFooterView()
        liaison.tableView(tableView, willDisplayHeaderView: view, forSection: 0)

        XCTAssertTrue(willDisplay)
    }

    func test_willDisplayFooterView_performsWillDisplayFooterViewSectionCommand() {

        let footer = TestTableViewSectionComponent()

        var willDisplay = false
        footer.set(command: .willDisplay) { _, _, _ in
            willDisplay = true
        }

        let section = TableViewSection(componentDisplayOption: .footer(component: footer))

        liaison.append(section: section)
        let view = UITableViewHeaderFooterView()
        liaison.tableView(tableView, willDisplayFooterView: view, forSection: 0)

        XCTAssertTrue(willDisplay)
    }

    func test_didEndDisplayingHeaderView_performsDidEndDisplayingHeaderViewSectionCommand() {

        let header = TestTableViewSectionComponent()

        var didEndDisplaying = false
        header.set(command: .didEndDisplaying) { _, _, _ in
            didEndDisplaying = true
        }

        let section = TableViewSection(componentDisplayOption: .header(component: header))

        liaison.append(section: section)
        let view = UITableViewHeaderFooterView()
        liaison.tableView(tableView, didEndDisplayingHeaderView: view, forSection: 0)

        XCTAssertTrue(didEndDisplaying)
    }

    func test_didEndDisplayingFooterView_performsDidEndDisplayingFooterViewSectionCommand() {

        let footer = TestTableViewSectionComponent()

        var didEndDisplaying = false
        footer.set(command: .didEndDisplaying) { _, _, _ in
            didEndDisplaying = true
        }

        let section = TableViewSection(componentDisplayOption: .footer(component: footer))

        liaison.append(section: section)
        let view = UITableViewHeaderFooterView()
        liaison.tableView(tableView, didEndDisplayingFooterView: view, forSection: 0)

        XCTAssertTrue(didEndDisplaying)
    }

    func test_prefetchRowsAtIndexPaths_performsPrefetchRowCommand() {
        let row = TestTableViewRow()
        var prefetch = false
        row.set(prefetchCommand: .prefetch) { _, _ in
            prefetch = true
        }

        let section = TableViewSection(rows: [row])

        liaison.append(section: section)
        liaison.tableView(tableView, prefetchRowsAt: [IndexPath(row: 0, section: 0)])

        XCTAssertTrue(prefetch)
    }

    func test_cancelPrefetchingForRowsAtIndexPaths_performsPrefetchRowCommand() {
        let row = TestTableViewRow()
        var cancel = false
        row.set(prefetchCommand: .cancel) { _, _ in
            cancel = true
        }

        let section = TableViewSection(rows: [row])

        liaison.append(section: section)
        liaison.tableView(tableView, cancelPrefetchingForRowsAt: [IndexPath(row: 0, section: 0)])

        XCTAssertTrue(cancel)
    }
    
    func test_rowForIndexPath_returnsCorrectRow() {
        let row1 = TestTableViewRow()
        let row2 = TestTableViewRow()
        
        let section = TableViewSection(rows: [row1, row2])
        liaison.append(section: section)
        let indexPath = IndexPath(row: 1, section: 0)

        let row = liaison.row(for: indexPath)
        XCTAssert(row === row2)
    }
    
    func test_rowForIndexPath_returnsNilForInvalidIndexPath() {
        let section = TableViewSection()
        
        liaison.append(section: section)
        let indexPath = IndexPath(row: 0, section: 0)
        XCTAssertNil(liaison.row(for: indexPath))
    }
    
}
