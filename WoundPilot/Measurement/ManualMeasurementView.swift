//  ManualMeasurementView.swift
//  WoundPilot

import SwiftUI
import PhotosUI

struct ManualMeasurementView: View {
    var onComplete: ((WoundMeasurementResult) -> Void)?
    
    @State private var lengthText = ""
    @State private var widthText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var loadedImage: UIImage?
    @State private var showValidationError = false
    
    // REMOVED: @Environment(\.dismiss) private var dismiss
    
    private var lengthCm: Float? {
        Float(lengthText.replacingOccurrences(of: ",", with: "."))
    }
    
    private var widthCm: Float? {
        Float(widthText.replacingOccurrences(of: ",", with: "."))
    }
    
    private var areaCm2: Float? {
        guard let L = lengthCm, let W = widthCm else { return nil }
        return L * W * 0.785
    }
    
    private var canSave: Bool {
        lengthCm != nil && widthCm != nil &&
        lengthCm! > 0 && widthCm! > 0 &&
        lengthCm! <= 100 && widthCm! <= 100
    }
    
    var body: some View {
        Form {
            Section {
                infoBox
            } header: {
                Text(LocalizedStrings.manualMeasurementHeaderTitle)
            }
            
            Section {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(.blue)
                        Text(LocalizedStrings.manualPhotoAddOptional)
                        Spacer()
                        if loadedImage != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } header: {
                Text(LocalizedStrings.manualPhotoSectionTitle)
            } footer: {
                Text(LocalizedStrings.manualPhotoHint)
            }
            
            Section {
                HStack {
                    Text(LocalizedStrings.manualLengthLabel)
                        .frame(width: 80, alignment: .leading)
                    TextField(LocalizedStrings.numericPlaceholderZero, text: $lengthText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text(LocalizedStrings.cmUnit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(LocalizedStrings.manualWidthLabel)
                        .frame(width: 80, alignment: .leading)
                    TextField(LocalizedStrings.numericPlaceholderZero, text: $widthText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text(LocalizedStrings.cmUnit)
                        .foregroundColor(.secondary)
                }
                
                if let area = areaCm2 {
                    HStack {
                        Text(LocalizedStrings.measureLabelArea)
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        Text("\(String(format: "%.1f", area)) \(LocalizedStrings.cm2Unit)")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(LocalizedStrings.manualMeasurementsSectionTitle)
            } footer: {
                Text(LocalizedStrings.manualMeasurementsHint)
            }
        }
        .navigationTitle(LocalizedStrings.manualEntryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // REMOVED: Cancel button - user can use system back button
            
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStrings.saveAction) {
                    saveAndComplete()
                }
                .disabled(!canSave)
            }
        }
        .alert(LocalizedStrings.manualInvalidMeasurementsTitle, isPresented: $showValidationError) {
            Button(LocalizedStrings.ok) {}
        } message: {
            Text(LocalizedStrings.manualInvalidMeasurementsMessage)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImage = image
                }
            }
        }
    }
    
    private var infoBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStrings.manualArUnavailable, systemImage: "info.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.blue)
            
            Text(LocalizedStrings.manualInfoText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func saveAndComplete() {
        guard let length = lengthCm,
              let width = widthCm,
              length > 0, width > 0,
              length <= 100, width <= 100 else {
            showValidationError = true
            return
        }
        
        let result = WoundMeasurementResult(
            lengthCm: length,
            widthCm: width,
            areaCm2: areaCm2,
            capturedImage: loadedImage,
            method: .manual,
            confidence: nil,
            timestamp: Date()
        )
        
        onComplete?(result)
        // REMOVED: dismiss() - let parent handle navigation
    }
}
