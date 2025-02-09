//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

class AddMoreRailItem: GalleryRailItem {
    func buildRailItemView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.33)

        let iconView = UIImageView(image: #imageLiteral(resourceName: "plus-24").withRenderingMode(.alwaysTemplate))
        iconView.tintColor = .ows_white
        view.addSubview(iconView)
        iconView.setCompressionResistanceHigh()
        iconView.setContentHuggingHigh()
        iconView.autoCenterInSuperview()

        return view
    }
}

extension AddMoreRailItem: Equatable {
    static func == (lhs: AddMoreRailItem, rhs: AddMoreRailItem) -> Bool {
        return true
    }
}

public struct AttachmentApprovalItem: Hashable {

    enum AttachmentApprovalItemError: Error {
        case noThumbnail
    }

    public let attachment: SignalAttachment

    // This might be nil if the attachment is not a valid image.
    let imageEditorModel: ImageEditorModel?
    // This might be nil if the attachment is not a valid video.
    let videoEditorModel: VideoEditorModel?
    let canSave: Bool

    public init(attachment: SignalAttachment, canSave: Bool) {
        self.attachment = attachment
        self.canSave = canSave

        self.imageEditorModel = AttachmentApprovalItem.imageEditorModel(for: attachment)
        if self.imageEditorModel == nil {
            self.videoEditorModel = AttachmentApprovalItem.videoEditorModel(for: attachment)
        } else {
            // Make sure we only have one of a video editor and an image editor, not both.
            self.videoEditorModel = nil
        }
    }

    private static func imageEditorModel(for attachment: SignalAttachment) -> ImageEditorModel? {
        guard attachment.isValidImage, !attachment.isAnimatedImage else {
            return nil
        }
        guard let dataUrl: URL = attachment.dataUrl, dataUrl.isFileURL else {
            owsFailDebug("Missing dataUrl.")
            return nil
        }

        let path = dataUrl.path
        do {
            return try ImageEditorModel(srcImagePath: path)
        } catch {
            owsFailDebug("Could not create image editor: \(error)")
            return nil
        }
    }

    private static func videoEditorModel(for attachment: SignalAttachment) -> VideoEditorModel? {
        guard attachment.isValidVideo, !attachment.isLoopingVideo else {
            return nil
        }
        guard let dataUrl: URL = attachment.dataUrl, dataUrl.isFileURL else {
            owsFailDebug("Missing dataUrl.")
            return nil
        }

        let path = dataUrl.path
        do {
            return try VideoEditorModel(srcVideoPath: path)
        } catch {
            owsFailDebug("Could not create image editor: \(error)")
            return nil
        }
    }

    // MARK: 

    var captionText: String? {
        return attachment.captionText
    }

    func getThumbnailImage() -> UIImage? {
        return self.attachment.staticThumbnail()
    }

    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(attachment)
    }

    // MARK: Equatable

    public static func == (lhs: AttachmentApprovalItem, rhs: AttachmentApprovalItem) -> Bool {
        return lhs.attachment == rhs.attachment
    }
}

// MARK: -

class AttachmentApprovalItemCollection {
    private (set) var attachmentApprovalItems: [AttachmentApprovalItem]
    let isAddMoreVisible: () -> Bool

    init(attachmentApprovalItems: [AttachmentApprovalItem], isAddMoreVisible: @escaping () -> Bool) {
        self.attachmentApprovalItems = attachmentApprovalItems
        self.isAddMoreVisible = isAddMoreVisible
    }

    func itemAfter(item: AttachmentApprovalItem) -> AttachmentApprovalItem? {
        guard let currentIndex = attachmentApprovalItems.firstIndex(of: item) else {
            owsFailDebug("currentIndex was unexpectedly nil")
            return nil
        }

        let nextIndex = attachmentApprovalItems.index(after: currentIndex)

        return attachmentApprovalItems[safe: nextIndex]
    }

    func itemBefore(item: AttachmentApprovalItem) -> AttachmentApprovalItem? {
        guard let currentIndex = attachmentApprovalItems.firstIndex(of: item) else {
            owsFailDebug("currentIndex was unexpectedly nil")
            return nil
        }

        let prevIndex = attachmentApprovalItems.index(before: currentIndex)

        return attachmentApprovalItems[safe: prevIndex]
    }

    func remove(item: AttachmentApprovalItem) {
        attachmentApprovalItems = attachmentApprovalItems.filter { $0 != item }
    }

    var count: Int {
        return attachmentApprovalItems.count
    }
}
