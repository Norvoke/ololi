//
//  ContentView.swift
//  ololi
//
//  Created by Finn Ellingwood on 4/7/24.
//

import SwiftUI

struct ContentView: View {
    @State private var emojiCards = ["🍎", "🍌", "🍇", "🍉", "🍓", "🍒", "🍑", "🍍"].doubled().shuffled()
    @State private var flippedCards = Set<Int>()
    @State private var matchedCards = Set<Int>()
    @State private var gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining = 90
    @State private var isGameOver = false
    @State private var showingTitleScreen = true // Control the display of the title screen
    @State private var selectedTime = 90 // Default to easy mode
    
    private let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if showingTitleScreen {
                    TitleScreenView(startGame: {
                        self.showingTitleScreen = false
                        self.timeRemaining = self.selectedTime
                    }, selectedTime: $selectedTime)
                } else {
                    GameTitleView() // Display the game title
                    if isGameOver {
                        GeometryReader { geo in
                            gameOverView
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    } else {
                        gameView
                    }
                }
            }
            .padding()
            .onReceive(gameTimer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    isGameOver = true
                    gameTimer.upstream.connect().cancel()
                }
            }
            .onChange(of: CGSize(width: geometry.size.width, height: geometry.size.height)) { newSize, _ in
                            // React to orientation change if needed
                        }
            .alert(isPresented: $isGameOver) {
                Alert(title: Text("Time's up!"), message: Text("Want to play again?"), primaryButton: .default(Text("Yes")) {
                    resetGame()
                }, secondaryButton: .cancel())
            }
        }
    }
    
    // Game title view component
    private func GameTitleView() -> some View {
        Text("ololi Emoji Match")
            .font(.largeTitle)
            .padding(.bottom, 20)
    }
    
    private var gameView: some View {
        VStack {
            HStack {
                Text("Time Remaining: \(timeRemaining)")
                    .font(.headline)
                    .padding(.bottom, 20)
                Spacer()
                Button("Reset", action: resetGame) // Add reset button
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(emojiCards.indices, id: \.self) { index in
                        CardView(symbol: emojiCards[index], isFlipped: flippedCards.contains(index), isMatched: matchedCards.contains(index)) {
                            if !matchedCards.contains(index) && flippedCards.count < 2 {
                                flipCard(at: index)
                            }
                        }
                    }
                }
            }
        }
    }

    
    private var gameOverView: some View {
        VStack {
            Text("Game Over")
                .font(.largeTitle)
            Text("You matched all the cards with \(timeRemaining) seconds remaining!")
                .font(.headline)
            Button("Play Again") {
                resetGame()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private func flipCard(at index: Int) {
        flippedCards.insert(index)
        
        if flippedCards.count == 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                checkForMatch()
            }
        }
    }
    
    private func checkForMatch() {
        let flippedIndexes = Array(flippedCards)
        if emojiCards[flippedIndexes[0]] == emojiCards[flippedIndexes[1]] {
            matchedCards.formUnion(flippedCards)
        }
        flippedCards.removeAll()
        
        if matchedCards.count == emojiCards.count {
            isGameOver = true
            gameTimer.upstream.connect().cancel()
        }
    }
    
    private func resetGame() {
        emojiCards = emojiCards.shuffled()
        flippedCards.removeAll()
        matchedCards.removeAll()
        isGameOver = false
        gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        timeRemaining = selectedTime // Reset time to selected time
        showingTitleScreen = true // Bring back the title screen
    }
}

// Title Screen View
struct TitleScreenView: View {
    var startGame: () -> Void
    @Binding var selectedTime: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Emoji Match")
                .font(.largeTitle)
            Picker(selection: $selectedTime, label: Text("Select Time")) {
                Text("Easy (90s)").tag(90)
                Text("Medium (60s)").tag(60)
                Text("Hard (30s)").tag(30)
            }
            .pickerStyle(SegmentedPickerStyle())
            Button("Start Game", action: startGame)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            Text("Developed by Finn Ellingwood")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .edgesIgnoringSafeArea(.all)
        .contentShape(Rectangle())
    }
}

struct CardView: View {
    var symbol: String
    var isFlipped: Bool
    var isMatched: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isFlipped || isMatched {
                    Text(symbol)
                        .font(.largeTitle)
                } else {
                    Rectangle()
                        .fill(Color.blue)
                }
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .foregroundColor(.white)
        .opacity(isMatched ? 0 : 1)
    }
}

extension Array {
    func doubled() -> [Element] {
        self + self
    }
}

//Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
