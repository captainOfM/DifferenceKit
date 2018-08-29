import UIKit
import DifferenceKit

private struct RandomModel: Differentiable {
    var id: Int
    var isUpdated: Bool

    var differenceIdentifier: Int {
        return id
    }

    init(_ id: Int, _ isUpdated: Bool = false) {
        self.id = id
        self.isUpdated = isUpdated
    }

    func isContentEqual(to source: RandomModel) -> Bool {
        return isUpdated == source.isUpdated
    }
}

private typealias RandomSection = ArraySection<RandomModel, RandomModel>

final class RandomViewController: UIViewController {
    private let collectionView: UICollectionView
    private var data = [RandomSection]()

    private var dataInput: [RandomSection] {
        get { return data }
        set {
            let changeset = StagedChangeset(source: data, target: newValue)
            collectionView.reload(using: changeset) { data in
                self.data = data
            }
        }
    }

    @objc private func refresh() {
        let defaultSourceSectionCount = 20
        let defaultSourceElementCount = 20

        func randomSection(modelIdRange: Range<Int>) -> ArraySection<RandomModel, RandomModel> {
            let modelId = Int.random(in: modelIdRange)
            let elementCount = Int.random(in: 0..<defaultSourceElementCount)
            var elementIds = Array(0..<elementCount)
            elementIds.shuffle()
            let elements = elementIds.map { RandomModel($0) }
            return ArraySection(model: RandomModel(modelId), elements: elements)
        }

        guard !data.isEmpty else {
            dataInput = (0..<defaultSourceSectionCount).map { _ in randomSection(modelIdRange: 0..<defaultSourceSectionCount) }
            return
        }

        let source = data
        var target = source

        let sourceSectionCount = source.count
        let deleteSectionCount = Int.random(in: 0..<sourceSectionCount / 4)
        let deletedSourceSectionCount = sourceSectionCount - deleteSectionCount
        let updateSectionCount = Int.random(in: 0..<deletedSourceSectionCount / 4)
        let moveSectionCount = Int.random(in: 0..<deletedSourceSectionCount / 4)
        let minInsertCount = defaultSourceSectionCount > sourceSectionCount ? deleteSectionCount : 0
        let insertSectionCount = Int.random(in: minInsertCount..<sourceSectionCount / 4)

        let deleteSectionIndices = (0..<deleteSectionCount).map { i in Int.random(in: 0..<sourceSectionCount - i) }
        let updateSectionIndices = (0..<updateSectionCount).map { i in Int.random(in: 0..<deletedSourceSectionCount) }
        let moveSectionIndexPairs = (0..<moveSectionCount).map { i in (source: Int.random(in: 0..<deletedSourceSectionCount), target: Int.random(in: 0..<deletedSourceSectionCount)) }
        let insertSectionIndices = (0..<insertSectionCount).map { i in Int.random(in: 0..<deletedSourceSectionCount + i) }

        for index in deleteSectionIndices {
            target.remove(at: index)
        }

        for index in target.indices {
            let sourceCount = target[index].elements.count
            let deleteCount = Int.random(in: 0..<sourceCount / 4)
            let deletedSourceCount = sourceCount - deleteCount
            let updateCount = Int.random(in: 0..<deletedSourceCount / 4)
            let moveCount = Int.random(in: 0..<deletedSourceCount / 4)
            let insertCount = Int.random(in: 0..<sourceCount / 4)

            let deleteIndices = (0..<deleteCount).map { i in Int.random(in: 0..<sourceCount - i) }
            let updateIndices = (0..<updateCount).map { i in Int.random(in: 0..<deletedSourceCount) }
            let moveIndexPairs = (0..<moveCount).map { i in (source: Int.random(in: 0..<deletedSourceCount), target: Int.random(in: 0..<deletedSourceCount)) }
            let insertIndices = (0..<insertCount).map { i in Int.random(in: 0..<deletedSourceCount + i) }

            for elementIndex in deleteIndices {
                target[index].elements.remove(at: elementIndex)
            }

            for elementIndex in updateIndices {
                target[index].elements[elementIndex].isUpdated.toggle()
            }

            for pair in moveIndexPairs {
                target[index].elements.swapAt(pair.source, pair.target)
            }

            for elementIndex in insertIndices {
                let elementId = sourceCount + elementIndex
                let element = RandomModel(elementId)
                target[index].elements.insert(element, at: elementIndex)
            }
        }

        for index in updateSectionIndices {
            target[index].model.isUpdated.toggle()
        }

        for pair in moveSectionIndexPairs {
            target.swapAt(pair.source, pair.target)
        }

        for index in insertSectionIndices {
            let modelId = sourceSectionCount + index
            let section = randomSection(modelIdRange: modelId..<modelId)
            target.insert(section, at: index)
        }

        dataInput = target
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        flowLayout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.size.width, height: 30)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

        super.init(nibName: nil, bundle: nil)

        title = "Random"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: UICollectionViewCell.reuseIdentifier)
        collectionView.register(TextCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: TextCollectionReusableView.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        let constraints = [
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RandomViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].elements.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewCell.reuseIdentifier, for: indexPath)
        let model = data[indexPath.section].elements[indexPath.item]
        cell.contentView.backgroundColor = model.isUpdated ? .yellow : .red
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let model = data[indexPath.section].model
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TextCollectionReusableView.reuseIdentifier, for: indexPath) as! TextCollectionReusableView
        view.text = "Section \(model.id)" + (model.isUpdated ? "+" : "")
        return view
    }
}

private extension UICollectionViewCell {
    static let reuseIdentifier = String(describing: self)
}
