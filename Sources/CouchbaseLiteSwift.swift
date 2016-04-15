//
//  CouchbaseLite.swift
//  CouchbaseLiteSwift
//
//  Created by Marco Betschart on 10.02.16.
//  Copyright © 2016 MANDELKIND. All rights reserved.
//

import CouchbaseLite

private var DatabaseDefaultConfigurationSingleton: CLSDatabaseConfiguration!

public typealias CLSDatabaseSchemaMigration = (CLSDatabase,UInt64) throws -> Void
public typealias CLSDatabaseSetup = (CLSDatabase) throws -> Void


/**
Configuration class for your Database.
To change the configuration of the default database use the following:


```
let config = CLSDatabase.defaultConfiguration()
config.schemaVersion = 3

CLSDatabase.defaultConfiguration = config
```
*/
public class CLSDatabaseConfiguration {
	public var directory = CBLManager.defaultDirectory()
	public var databaseName = "database"
	public var databaseSetup: CLSDatabaseSetup? = nil
	public var schemaMigration: CLSDatabaseSchemaMigration? = nil
	public var schemaVersion: UInt64 = 0
	
	public init(){}
	
	public init(databaseName: String){
		self.databaseName = databaseName
	}
	
	public init(databaseName: String, directory: String){
		self.databaseName = databaseName
		self.directory = directory
	}
}


/**
The CLSDatabase class handles the connections and schema updates of your CouchbaseLite database.
*/
public class CLSDatabase {
	
	struct Static {
		static var maintainIfNeeded = true
	}
	
	
	public static var defaultConfiguration: CLSDatabaseConfiguration{
		get{
			if DatabaseDefaultConfigurationSingleton == nil{
				DatabaseDefaultConfigurationSingleton = CLSDatabaseConfiguration()
			}
		
			return DatabaseDefaultConfigurationSingleton
		}
		set(configuration){
			DatabaseDefaultConfigurationSingleton = configuration
		}
	}
	
	///Returns the default database using the `defaultConfiguration`
	public class func defaultDatabase() -> CLSDatabase{
		return CLSDatabase(configuration: CLSDatabase.defaultConfiguration)
	}
	
	
	public var configuration: CLSDatabaseConfiguration
	
	public var path: String?{
		return self.url.path
	}
	
	public var url: NSURL{
		return NSURL(fileURLWithPath: self.configuration.directory, isDirectory: true)
			.URLByAppendingPathComponent(self.configuration.databaseName)
			.URLByAppendingPathExtension("cblite2")
	}
	
	public var schemaVersion: UInt64?{
		get{
			if let schemaVersion = NSUserDefaults.standardUserDefaults().valueForKey("DatabaseSchemaVersion$\(self.configuration.databaseName)") as? NSNumber{
				return schemaVersion.unsignedLongLongValue
			}
			
			return nil
		}
		set{
			if let schemaVersion = newValue{
				NSUserDefaults.standardUserDefaults().setValue(NSNumber(unsignedLongLong: schemaVersion), forKey: "DatabaseSchemaVersion$\(self.configuration.databaseName)")
				NSUserDefaults.standardUserDefaults().synchronize()
			}
		}
	}
	
	public var needsSchemaMigration: Bool{
		if self.schemaVersion == nil, let setupDidRunAt = self.setupDidRunAt where setupDidRunAt.timeIntervalSinceNow < -10{
			return true
			
		} else if let schemaVersion = self.schemaVersion where schemaVersion < self.configuration.schemaVersion{
			return true
		}
		
		return false
	}
	
	public var needsSetup: Bool{
		return self.setupDidRunAt == nil
	}
	
	private var setupDidRunAt: NSDate?{
		get{
			return NSUserDefaults.standardUserDefaults().valueForKey("DatabaseSetupDidRun$\(self.configuration.databaseName)") as? NSDate
		}
		set{
			NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "DatabaseSetupDidRun$\(self.configuration.databaseName)")
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	
	
	public convenience init( databaseName: String ){
		self.init( configuration: CLSDatabaseConfiguration(databaseName: databaseName) )
	}
	
	
	public init(configuration: CLSDatabaseConfiguration){
		self.configuration = configuration
		
		//maintenance is done only once in the lifetime of the app
		guard Static.maintainIfNeeded else {
			return
		}
		Static.maintainIfNeeded = false
		
		if self.needsSetup, let databaseSetup = self.configuration.databaseSetup{
			do{
				try databaseSetup(self)
				
			} catch let error as NSError{
				fatalError(error.description)
			}
			
			self.setupDidRunAt = NSDate()
			if self.schemaVersion == nil{
				self.schemaVersion = self.configuration.schemaVersion
			}
		}
		
		if self.needsSchemaMigration, let schemaMigration = self.configuration.schemaMigration{
			let oldSchemaVersion = self.schemaVersion ?? 0
			
			do{
				try schemaMigration(self,oldSchemaVersion)
				self.schemaVersion = self.configuration.schemaVersion
				
			} catch let error as NSError{
				fatalError(error.description)
			}
		}
	}
	
	
	public func connection() throws -> CBLDatabase{
		return try CBLManager(directory: self.configuration.directory, options: nil).databaseNamed(self.configuration.databaseName)
	}
}


/**
Generic AnyModel class which provides convenience functions
for your own Model classes.
*/
public class CLSModel: CBLModel{
	
	///Convenience function to create a new model
	public class func create() throws -> Self{
		return try self.create( CLSDatabase.defaultDatabase() )
	}
	
	
	///Convenience function to create a new model using an existing database connection
	public class func create(connection: CBLDatabase) -> Self{
		return self.init(forNewDocumentInDatabase: connection)
	}
	
	
	///Convenience function to create a new model using an existing database
	public class func create(database: CLSDatabase) throws -> Self{
		return self.create(try database.connection())
	}
	
	
	///Convenience function to create a new model and populate it with the given properties
	public class func create(from: [String: AnyObject?]) throws -> Self{
		return try self.create(CLSDatabase.defaultDatabase(),from: from )
	}
	
	
	///Convenience function to create a new model using a given database and populate it with properties
	public class func create(database: CLSDatabase, from: [String: AnyObject?]) throws -> Self{
		return self.create(try database.connection(), from: from)
	}
	
	
	///Convenience function to create a new model using a given database connection and populate it with properties
	public class func create(connection: CBLDatabase, from: [String: AnyObject?]) -> Self{
		let model = self.init(forNewDocumentInDatabase: connection)
		
		for (property,value) in from{
			model.setValue(value, ofProperty: property)
		}
		
		return model
	}
	
	
	///Convenience function to load an existing model
	public class func load(docID: String) throws -> Self?{
		return try self.load(CLSDatabase.defaultDatabase(), withID: docID)
	}
	
	
	///Convenience function to load an existing model from the given database
	public class func load(database: CLSDatabase, withID docID: String) throws -> Self?{
		return self.load(try database.connection(), withID: docID)
	}
	
	
	///Convenience function to load an existing model using the given database connection
	public class func load(connection: CBLDatabase, withID docID: String) -> Self?{
		if let doc = connection.documentWithID(docID){
			return self.init(forDocument: doc)
		}
		
		return nil
	}
	
	
	///Type of the model as String
	public override func getValueOfProperty(property: String) -> AnyObject? {
		if property == "type" && super.getValueOfProperty(property) == nil {
			return self.dynamicType.valueOfTypeProperty()
		}
		
		return super.getValueOfProperty(property)
	}
	
	
	public class func valueOfTypeProperty() -> String?{
		return NSStringFromClass(self)
	}
	
	
	public override func propertiesToSave() -> [NSObject : AnyObject] {
		var properties = super.propertiesToSave()
		properties["type"] = self.dynamicType.valueOfTypeProperty()
		
		return properties
	}
	
	
	public override func isEqual(object: AnyObject?) -> Bool {
		if let model = object as? CLSModel, let id = model.document?.documentID, let type = model.type{
			return id == self.document?.documentID && type == self.type
		}
		
		return super.isEqual(object)
	}
	
	
	private var _attachmentsDidLoad = false
	private var _attachments: [CLSAttachment]? = nil
	
	
	///All attachments of the model
	public var attachments: [CLSAttachment]?{
		get{
			if !self._attachmentsDidLoad{
				self._attachments = loadAttachments()
				self._attachmentsDidLoad = true
			}
			
			return self._attachments
		}
		set(newAttachments){
			if let newAttachments = newAttachments{
				if let oldAttachments = self._attachments{
					for oldAttachment in oldAttachments{
						if newAttachments.indexOf(oldAttachment) == nil{
							oldAttachment.removeAsAttachment()
						}
					}
				}
				
				for newAttachment in newAttachments{
					newAttachment.model = self
				}
			}
			saveAttachments(newAttachments) //maybe this should better be called in willSave()...?
			
			self._attachmentsDidLoad = true
			self._attachments = newAttachments
		}
	}
	
	
	///Function can be overriden to exclude specific attachments for example
	public func loadAttachments() -> [CLSAttachment]?{
		if let attachmentNames = self.attachmentNames{
			return attachmentNames.flatMap{
				if let attachment = self.attachmentNamed($0){
					return CLSAttachment(model: self){
						$0.attachmentIdentifier = attachment.name
						
						$0.attachmentName = attachment.name
						$0.attachmentContent = attachment.content
						$0.attachmentContentType = attachment.contentType
					}
				}
				
				return nil
			}
		}
		
		return nil
	}
	
	
	public func saveAttachments(attachments: [CLSAttachment]?){
		if let newAttachments = attachments{
			for newAttachment in newAttachments{
				newAttachment.saveAsAttachment()
			}
		}
	}
}


public protocol CLSAttachmentType: Equatable {
	var attachmentIdentifier: String? { get set }
	var attachmentType: String? { get set }
	
	var attachmentName: String? { get set }
	var attachmentContentType: String? { get set }
	var attachmentContent: NSData? { get set }
	
	func saveAsAttachment()
	func removeAsAttachment()
}


/**
Generic CLSAttachment class which provides a interface,
to customize the behaviour of specific custom Attachments.
*/
public class CLSAttachment: NSObject,CLSAttachmentType{
	var model: CLSModel?
	
	public var attachmentIdentifier: String?
	public var attachmentType: String?
	
	public var attachmentName: String?
	public var attachmentContentType: String?
	public var attachmentContent: NSData?
	
	
	public required init(model: CLSModel?, configure: ( (CLSAttachment) -> Void )?){
		self.model = model
		super.init()
		configure?(self)
	}
	
	
	public func saveAsAttachment(){
		if let identifier = self.attachmentIdentifier where self.attachmentName != identifier{
			self.model?.removeAttachmentNamed(identifier)
		}
		
		if let name = self.attachmentName, let contentType = self.attachmentContentType, let content = self.attachmentContent{
			self.model?.setAttachmentNamed(name, withContentType: contentType, content: content)
		}
		
		self.attachmentIdentifier = self.attachmentName
	}
	
	
	public func removeAsAttachment(){
		if let identifier = self.attachmentIdentifier{
			self.model?.removeAttachmentNamed(identifier)
		}
	}
	
	
	public func copyWithZone(zone: NSZone) -> AnyObject { // Support for NSCopying
		return self.dynamicType.init(model: self.model){
			$0.attachmentIdentifier = self.attachmentIdentifier
			$0.attachmentType = self.attachmentType
			
			$0.attachmentName = self.attachmentName
			$0.attachmentContentType = self.attachmentContentType
			$0.attachmentContent = self.attachmentContent
		}
	}
}


public func == (lhs: CLSAttachment, rhs: CLSAttachment) -> Bool{
	return lhs.model == rhs.model && lhs.attachmentIdentifier == rhs.attachmentIdentifier
}


public enum CLSQuerySortOrder: String{
	case ASC = ""
	case DESC = "-"
}


internal struct CLSQuerySort{
	var property: String?
	var order: CLSQuerySortOrder?
	
	init(property: String, order: CLSQuerySortOrder){
		self.property = property
		self.order = order
	}
}


private var CLSQueryBuilderCache = [String: CBLQueryBuilder]()

/**
Query your CouchbaseLite database with this super easy wrapper.
*/
public class CLSQuery<T: CLSModel>: LazySequenceType,CollectionType{
	private var enumerator: CBLQueryEnumerator?
	private var format: String?
	private var params: [String: AnyObject]?
	private var sorts = [CLSQuerySort]()
	private var database: CLSDatabase?
	private var tiedToConnection: CBLDatabase?
	
	public var title: String?
	public var type: CLSModel.Type
	
	
	convenience public init(){
		self.init(database: CLSDatabase.defaultDatabase(), type: T.self, title: nil)
	}
	
	
	convenience public init(connection: CBLDatabase){
		self.init(connection: connection, type: T.self, title: nil)
	}
	
	
	convenience public init(connection: CBLDatabase, type: CLSModel.Type){
		self.init(connection: connection, type: type, title: nil)
	}
	
	
	public init(connection: CBLDatabase, type: CLSModel.Type, title: String?){
		self.tiedToConnection = connection
		self.type = type
		self.title = title
	}
	
	
	convenience public init(title: String?){
		self.init(database: CLSDatabase.defaultDatabase(), type: T.self, title: title)
	}
	
	
	convenience public init(database: CLSDatabase){
		self.init(database: database, type: T.self, title: nil)
	}
	
	
	convenience public init(database: CLSDatabase, title: String?){
		self.init(database: database, type: T.self, title: title)
	}
	
	
	convenience public init(type: CLSModel.Type){
		self.init(database: CLSDatabase.defaultDatabase(), type: type, title: nil)
	}
	
	
	convenience public init(type: CLSModel.Type, title: String?){
		self.init(database: CLSDatabase.defaultDatabase(), type: type, title: title)
	}
	
	
	convenience public init(database: CLSDatabase, type: CLSModel.Type){
		self.init(database: CLSDatabase.defaultDatabase(), type: type, title: nil)
	}
	
	
	public init(database: CLSDatabase, type: CLSModel.Type, title: String?){
		self.database = database
		self.type = type
		self.title = title
	}
	
	
	private func connection() throws -> CBLDatabase{
		if let connection = self.tiedToConnection{
			return connection
		}
		
		return try database!.connection()
	}
	
	
	/**
	Limit the query results by setting condtions using NSPredicate syntax.
	
	Simple query with hard coded parameters:
	```
	.conditions("age > 15")
	```
	
	Conditions using dynamic parameters:
	
	```
	.conditions("givenName == $givenName")
	```
	
	- SeeAlso:
	- [NSPredicate - NSHipster](http://nshipster.com/nspredicate/)
	- [NSPredicate Class Reference](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/)
	*/
	public func conditions(format: String) -> CLSQuery<T>{
		self.format = format.characters.count > 0 ? format : nil
		
		return self
	}
	
	
	/**
	Limit the query results by setting condtions using NSPredicate syntax.
	This function uses query notation for specifying complex query in a easy readable format:
	
	```
	.conditions([
	"givenName == $givenName",
	"AND familyName == $familyName",
	"AND age > 15"
	])
	```
	
	- SeeAlso:
	- [NSPredicate - NSHipster](http://nshipster.com/nspredicate/)
	- [NSPredicate Class Reference](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/)
	*/
	public func conditions(format: [String]) -> CLSQuery<T>{
		self.format = format.count > 0 ? format.joinWithSeparator(" ") : nil
		
		return self
	}
	
	
	/**
	Pass in NSPredicate parameters for dynamic queries:
	
	```
	.params([
	"givenName": "Marco",
	"familyName": "Betschart"
	])
	```
	
	- SeeAlso:
	- [NSPredicate - NSHipster](http://nshipster.com/nspredicate/)
	- [NSPredicate Class Reference](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/)
	*/
	public func params(params: [String: AnyObject]?) -> CLSQuery<T>{
		self.params = params
		
		return self
	}
	
	
	/**
	Sort the query:
	
	```
	.sort("familyName",order: .ASC)
	.sort("age",order: .DESC)
	```
	*/
	public func sort(property: String, order: CLSQuerySortOrder = .ASC) -> CLSQuery<T>{
		self.sorts.append( CLSQuerySort(property: property, order: order) )
		
		return self
	}
	
	
	/**
	Convenience function to mass delete all documents of the query
	*/
	public func deleteDocuments() throws -> CLSQuery<T>{
		for model in self{
			try model.deleteDocument()
		}
		
		return self
	}
	
	
	/**
	Get a simple array of T
	*/
	public func models() -> [T]{
		return self.map{
			return $0
		}
	}
	
	
	private func fetch(force: Bool = false){
		if force || self.enumerator == nil{
			self.enumerator = nil
			
			let wherePredicate = NSPredicate(format: {
				if let type = self.type.valueOfTypeProperty(), let whereFormat = self.format{
					return "type == '\(type)' AND ( \(whereFormat) )"
					
				} else if let type = self.type.valueOfTypeProperty(){
					return "type == '\(type)'"
					
				} else if let whereFormat = self.format{
					return whereFormat
				}
				
				return "1 == 1"
				}())
			
			let withContext: [String: AnyObject] = {
				func serialize(value: AnyObject?) -> AnyObject?{
					if let model = value as? CLSModel{
						return model.document?.documentID ?? ""
						
					} else if let oldValue = value as? [AnyObject]{
						var newValue = [AnyObject]()
						
						for oldItem in oldValue{
							if let newItem = serialize(oldItem){
								newValue.append(newItem)
							}
						}
						
						return newValue
					}
					
					return value
				}
				
				if var context = self.params{
					for (key,value) in context{
						context[key] = serialize(value)
					}
					
					return context
				}
				
				return [:]
			}()
			
			let orderBy: [String] = self.sorts.map{ sort in
				if let property = sort.property, let order = sort.order{
					return "\(order.rawValue)\(property)"
					
				} else if let property = sort.property{
					return property
				}
				
				return ""
			}
			
			do{
				let queryBuilderCacheId = wherePredicate.description + " ORDER BY " + orderBy.joinWithSeparator(" ")
				
				if CLSQueryBuilderCache[queryBuilderCacheId] == nil{
					CLSQueryBuilderCache[queryBuilderCacheId] = try CBLQueryBuilder(
						database: try self.connection(),
						select: nil,
						wherePredicate: wherePredicate,
						orderBy: orderBy
					)
				}
				
				if let queryBuilder = CLSQueryBuilderCache[queryBuilderCacheId]{
					self.enumerator = try queryBuilder.runQueryWithContext(withContext)
				}
				
			} catch _ {}
		}
	}
	
	
	public func generate() -> AnyGenerator<T> {
		self.fetch(true)
		
		return AnyGenerator{
			guard let enumerator = self.enumerator, let nextRow = enumerator.nextRow(), let document = nextRow.document else {
				return nil
			}
			
			return self.type.init(forDocument: document) as? T
		}
	}
	
	
	public var count: Int {
		self.fetch(true)
		
		if let enumerator = self.enumerator{
			return Int(enumerator.count)
		}
		
		return 0
	}
	
	
	public var startIndex: Int {
		return 0
	}
	
	
	public var endIndex: Int {
		self.fetch(false)
		
		if let enumerator = self.enumerator{
			return Int(enumerator.count)
		}
		
		return 0
	}
	
	
	public subscript(i: Int) -> T {
		self.fetch(false)
		
		guard let enumerator = self.enumerator else{
			fatalError("enumerator is nil")
		}
		
		let count = Int(enumerator.count)
		guard count > i else {
			fatalError("index out of range")
		}
		
		let document = enumerator.rowAtIndex(UInt(i)).document
		guard let doc = document else {
			fatalError("document is nil")
		}
		
		return self.type.init(forDocument: doc) as! T
	}
}
