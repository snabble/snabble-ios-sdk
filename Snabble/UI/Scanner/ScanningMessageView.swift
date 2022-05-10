//
//  ScanningMessageView.swift
//  Snabble
//
//  Created by Anastasia Mishur on 29.04.22.
//

final class ScanningMessageView: UIView {

    public weak var imageView: UIImageView?
    public weak var label: UILabel?
    public weak var spinner: UIActivityIndicatorView?
    public var imageWidth: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(Asset.SnabbleSDK.iconClose.image, for: .normal)

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        if #available(iOS 13.0, *) {
            spinner.style = .medium
        } else {
            spinner.style = .gray
        }

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .label
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator

        addSubview(closeButton)
        addSubview(imageView)
        addSubview(spinner)
        addSubview(label)
        addSubview(separator)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            closeButton.widthAnchor.constraint(equalToConstant: 33),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            imageView.widthAnchor.constraint(equalToConstant: 0).usingVariable(&imageWidth).usingPriority(.defaultHigh + 1),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).usingPriority(.defaultHigh + 1),
            imageView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 2),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: separator.topAnchor, constant: -8),

            spinner.topAnchor.constraint(equalTo: imageView.topAnchor),
            spinner.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            spinner.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            spinner.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(lessThanOrEqualTo: separator.topAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -8)
        ])

        self.imageView = imageView
        self.spinner = spinner
        self.label = label
    }
}
