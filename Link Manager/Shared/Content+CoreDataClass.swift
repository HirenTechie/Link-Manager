import Foundation
import CoreData

@objc(Content)
public class Content: NSManagedObject {

}

extension Content {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Content> {
        return NSFetchRequest<Content>(entityName: "Content")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var thumbIconUrl: String?
    @NSManaged public var savedLinkUrl: String?
    @NSManaged public var domainName: String?
    @NSManaged public var domainIconUrl: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var creationDate: Date?
    @NSManaged public var category: Category?

}

extension Content : Identifiable {

}
