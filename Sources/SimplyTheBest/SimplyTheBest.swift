import ArgumentParser
import Foundation

@main
public struct SimplyTheBest: ParsableCommand {

	public static let configuration = CommandConfiguration(abstract: "A Swift command-line tool find the fastest implementations of 67-phonebook amon several projects.")
	
	@Argument(help: "The root directory for all the student projects.")
	private var rootDirectory: String

	@Argument(help: "Output file name where to write the stats, without file name extension.")
	private var outputFile: String

	public init() {
	}

	public func run() throws {
		do {
			let allEntries = try enumerateStats()
			try writeEntries(allEntries, to: outputFile)
			print("==> Finished <== ")
		} catch {
			print("ERROR: Failed to read stats \(error.localizedDescription)")
		}
	}
	
	private func enumerateStats() throws -> [ImplementationStats] {
		guard let rootURL = URL(string: rootDirectory) else {
			print("Not valid URL at \(rootDirectory)")
			throw Errors.rootDoesNotExist
		}

		var entries = [ImplementationStats]()
		var hadStatsFileCount = 0
		var didNotHaveStatsFileCount = 0
		
		print("Reading stats from \(rootDirectory)")

		let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .isRegularFileKey])
		let directoryEnumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
		
		for case let fileURL as URL in directoryEnumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
					let isDirectory = resourceValues.isDirectory
			else {
				print("Not a directory, skipping: \(fileURL)")
				continue
			}
			if isDirectory {
				let studentID = fileURL.lastPathComponent
				let statsFileURL = fileURL.appending(path: "67-phonebook/compare.csv")
				if FileManager.default.fileExists(atPath: statsFileURL.path()) {
					print("Handling stats from \(studentID)...")
					var hashTableTime = -1
					var bstTime = -1
					var statsOfWhichDictionary = ""
					let lines = try String(contentsOfFile: statsFileURL.path()).components(separatedBy: "\n")
					for line in lines {
						if line.isEmpty {
							continue
						}
						if line.hasPrefix("Hashtable:") {
							statsOfWhichDictionary = "HashTable"
						} else if line.hasPrefix("Binary search tree:") {
							statsOfWhichDictionary = "BST"
						}
						if line.hasPrefix("megalopolis.txt") {
							let items = line.split(separator: ",")
							if items.count == 4 {
								if statsOfWhichDictionary == "HashTable" {
									hashTableTime = Int(items[3]) ?? -1
								} else if statsOfWhichDictionary == "BST" {
									bstTime = Int(items[3]) ?? -1
								}
							}
						}
					}
					if !studentID.isEmpty && hashTableTime > 0 && bstTime > 0 {
						print("Stats for \(studentID) added to statistics")
						entries.append(ImplementationStats(studentID: studentID, hashTableSpeed: hashTableTime, bstSpeed: bstTime))
						hadStatsFileCount += 1
					} else {
						didNotHaveStatsFileCount += 1
						print("Failed to read stats for hashtable and bst for \(studentID)")
					}
				} else {
					didNotHaveStatsFileCount += 1
					print("No stats for \(studentID)")
				}
				directoryEnumerator.skipDescendants()
			}
		}
		print("\(hadStatsFileCount) had stats, \(didNotHaveStatsFileCount) did not have stats")
		print("Creates stats for \(entries.count) projects")
		return entries
	}
	
	private func writeEntries(_ entries: [ImplementationStats], to fileName: String) throws {
		let fileURL = URL(fileURLWithPath: fileName + ".csv")
		print("Writing to \(fileURL.path())")
		try "".data(using: .utf8)?.write(to: fileURL)
		if let handle = try? FileHandle(forWritingTo: fileURL) {
			handle.write("StudentID,Hashtable speed,StudentID,BST speed\n".data(using: .utf8)!)
			for entry in entries {
				handle.write("\(entry.studentID),\(entry.hashTableSpeed),\(entry.studentID),\(entry.bstSpeed)\n".data(using: .utf8)!)
			}
			try handle.close()
		}
	}
	
}
