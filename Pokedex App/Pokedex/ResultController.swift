//
//  ResultController.swift
//  Pokedex
//
//  Created by Ricardo Hernandez on 18/08/21.
//

import UIKit

final class ResultController: UIViewController {
    
    @IBOutlet weak private var nameLabel: UILabel!
    
    var pokemonClass: PokemonClassifierOutput?
    
    override func viewWillAppear(_ animated: Bool) {
        guard let pokemon = pokemonClass else { return }
        nameLabel.text = pokemon.classLabel
    }
    
}
