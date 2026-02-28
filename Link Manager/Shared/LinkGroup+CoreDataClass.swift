import CoreData
import Foundation

@objc(LinkGroup)
public class LinkGroup: NSManagedObject {

}

extension LinkGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LinkGroup> {
        return NSFetchRequest<LinkGroup>(entityName: "LinkGroup")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var symbol: String?
    @NSManaged public var desc: String?
    @NSManaged public var links: NSSet?

}

// MARK: Generated accessors for links
extension LinkGroup {

    @objc(addLinksObject:)
    @NSManaged public func addToLinks(_ value: Content)

    @objc(removeLinksObject:)
    @NSManaged public func removeFromLinks(_ value: Content)

    @objc(addLinks:)
    @NSManaged public func addToLinks(_ values: NSSet)

    @objc(removeLinks:)
    @NSManaged public func removeFromLinks(_ values: NSSet)

}

extension LinkGroup: Identifiable {

}
