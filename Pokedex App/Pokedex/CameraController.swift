//
//  CameraController.swift
//  Pokedex
//
//  Created by Ricardo Hernandez on 18/08/21.
//

import UIKit
import AVFoundation
import CoreML

final class CameraController: UIViewController {
    
    private lazy var session: AVCaptureSession? = {
        let session = AVCaptureSession()
        let dataOutput = AVCaptureVideoDataOutput()
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: captureDevice),
              session.canAddInput(videoInput),
              session.canAddOutput(dataOutput) else { return nil }
        session.addInput(videoInput)
        session.addOutput(dataOutput)
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.startRunning()
        return session
        
    }()
    
    private lazy var previewCameraLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = session else {
            return nil
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = cameraView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }()
    
    @IBOutlet weak var cameraView: UIView!
    
    private let model: PokemonClassifier = {
        let config = MLModelConfiguration()
        guard let model = try? PokemonClassifier(configuration: config) else {
            fatalError("Can't create model")
        }
        return model
    }()
    
    private var output: PokemonClassifierOutput?
    
    override func viewWillAppear(_ animated: Bool) {
        guard let cameraLayer = previewCameraLayer else {
            fatalError("Tu dispositivo no soporta lectura de QR. Usa un dispositivo con camara")
        }
        cameraView.layer.addSublayer(cameraLayer)
    }
    
    @IBAction func pokeButtonClicked(_ sender: Any) {
        playPokedexSound()
        showPokemonClassification()
    }
    
    private func playPokedexSound() {
        if let soundURL = Bundle.main.url(forResource: "pokedex", withExtension: "wav") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound);
        }
    }
    
    private func showPokemonClassification() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let resultController = storyboard.instantiateViewController(withIdentifier: "ResultController") as? ResultController else { return }
        resultController.pokemonClass = self.output
        resultController.modalPresentationStyle = .pageSheet
        present(resultController, animated: true, completion: nil)
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let result = try? model.prediction(image: pixelBuffer) else {
            fatalError("Can't get a result")
        }
        self.output = result
    }
}
