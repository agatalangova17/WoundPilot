//  ManualMeasurementView.swift
//  WoundPilot
//
//  Manual measurement entry with optional photo

import SwiftUI
import PhotosUI

struct ManualMeasurementView: View {
    var onComplete: ((WoundMeasurementResult) -> Void)?
    
    @State private var lengthText = ""
    @State private var widthText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var loadedImage: UIImage?
    @State private var showValidationError = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var lengthCm: Float? {
        Float(lengthText.replacingOccurrences(of: ",", with: "."))
    }
    
    private var widthCm: Float? {
        Float(widthText.replacingOccurrences(of: ",", with: "."))
    }
    
    private var areaCm2: Float? {
        guard let L = lengthCm, let W = widthCm else { return nil }
        return L * W * 0.785 // Ellipse approximation
    }
    
    private var canSave: Bool {
        lengthCm != nil && widthCm != nil &&
        lengthCm! > 0 && widthCm! > 0 &&
        lengthCm! <= 100 && widthCm! <= 100 // Sanity check
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    infoBox
                } header: {
                    Text("Manual Measurement")
                }
                
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(.blue)
                            Text("Add Photo (Optional)")
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
                    Text("Photo")
                } footer: {
                    Text("For best results, include a ruler or coin in the photo for reference")
                }
                
                Section {
                    HStack {
                        Text("Length")
                            .frame(width: 80, alignment: .leading)
                        TextField("0.0", text: $lengthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Width")
                            .frame(width: 80, alignment: .leading)
                        TextField("0.0", text: $widthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    if let area = areaCm2 {
                        HStack {
                            Text("Area")
                                .frame(width: 80, alignment: .leading)
                            Spacer()
                            Text(String(format: "%.1f cm²", area))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Measurements")
                } footer: {
                    Text("Measure the longest axis for length and the widest perpendicular point for width")
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndComplete()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Invalid Measurements", isPresented: $showValidationError) {
                Button("OK") {}
            } message: {
                Text("Please enter valid measurements between 0.1 and 100 cm")
            }
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
            Label("AR measurement unavailable", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.blue)
            
            Text("Use a ruler to measure the wound's length (longest dimension) and width (widest perpendicular point). Optionally add a photo with a reference object visible.")
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
    }
}

#Preview {
    ManualMeasurementView()
}
