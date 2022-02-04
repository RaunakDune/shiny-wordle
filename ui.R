library(shiny)
library(htmltools)
#library(rsconnect)

source("tomble_wordlist.R")

fluidPage(
  theme = bslib::bs_theme(version = 4),
  title = "Tomble - A Locked Tomb-inspired Wordle App",
  tags$style(HTML("
  body {
    background-color: #081b29;
  }
  h1, h2, h3, h4 {
    color: white;
  }
  .container-fluid {
      text-align: center;
      height: calc(100vh - 30px);
      display: grid;
      grid-template-rows: 1fr auto;
  }
  .guesses {
      overflow-y: auto;
      height: 100%;
  }
  .guesses.finished {
      overflow-y: visible;
  }
  .guesses .word {
      margin: 5px;
  }
  .guesses .word > .letter {
      display: inline-block;
      width: 50px;
      height: 50px;
      text-align: center;
      vertical-align: middle;
      border-radius: 3px;
      line-height: 50px;
      font-size: 32px;
      font-weight: bold;
      vertical-align: middle;
      user-select: none;
      color: white;
      font-family: 'Clear Sans', 'Helvetica Neue', Arial, sans-serif;
  }
  .guesses .word > .correct {
      background-color: #6a5;
  }
  .guesses .word > .in-word {
      background-color: #db5;
  }
  .guesses .word > .not-in-word {
      background-color: #888;
  }
  .guesses .word > .guess {
      color: black;
      background-color: white;
      border: 1px solid black;
  }
  .keyboard {
      height: 240px;
      user-select: none;
  }
  .keyboard .keyboard-row {
      margin: 3px;
  }
  .keyboard .keyboard-row .key {
      display: inline-block;
      padding: 0;
      width: 30px;
      height: 50px;
      text-align: center;
      vertical-align: middle;
      border-radius: 3px;
      line-height: 50px;
      font-size: 18px;
      font-weight: bold;
      vertical-align: middle;
      color: black;
      font-family: 'Clear Sans', 'Helvetica Neue', Arial, sans-serif;
      background-color: #ddd;
      touch-action: none;
  }
  .keyboard .keyboard-row .key:focus {
      outline: none;
  }
  .keyboard .keyboard-row .key.wide-key {
      font-size: 15px;
      width: 50px;
  }
  .keyboard .keyboard-row .key.correct {
      background-color: #6a5;
      color: white;
  }
  .keyboard .keyboard-row .key.in-word {
      background-color: #db5;
      color: white;
  }
  .keyboard .keyboard-row .key.not-in-word {
      background-color: #888;
      color: white;
  }
  .endgame-content {
      font-family: Helvetica, Arial, sans-serif;
      display: inline-block;
      line-height: 1.4;
      letter-spacing: .2em;
      margin: 20px 8px;
      width: fit-content;
      padding: 20px;
      border-radius: 5px;
      box-shadow: 4px 4px 19px rgb(0 0 0 / 17%);
  }
")),
  div(
    class = "guesses",
    h1("Tomble"),
    h4("A Wordle Subset for The Locked Tomb"),
    uiOutput("previous_guesses"),
    uiOutput("current_guess"),
    uiOutput("endgame"),
    uiOutput("new_game_ui")
  ),
  uiOutput("keyboard"),
  # div(
  #   style="display: inline-block;",
  #   checkboxInput("hard", "Hard mode")
  # ),
  tags$script(HTML("
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
                     'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
    const all_key_ids = [ ...letters, 'Enter', 'Back'];
    document.addEventListener('keydown', function(e) {
      let key = e.code.replace(/^Key/, '');
      if (letters.includes(key)) {
        document.getElementById(key).click();
      } else if (key == 'Enter') {
        document.getElementById('Enter').click();
      } else if (key == 'Backspace') {
        document.getElementById('Back').click();
      }
    });

    // For better responsiveness on touch devices, trigger a click on the button
    // when a touchstart event occurs; don't wait for the touchend event. So
    // that a click event doesn't happen when the touchend event happens (and
    // cause the letter to be typed a second time), we set the 'pointer-events'
    // CSS property to 'none' on the button. Then when there's _any_ touchend
    // event, unset the 'pointer-events' CSS property on all of the buttons, so
    // that the button can be touched again.
    let in_button_touch = false;
    document.addEventListener('touchstart', function(e) {
        if (all_key_ids.includes(e.target.id)) {
            e.target.click();
            e.target.style.pointerEvents = 'none';
            e.preventDefault();   // Disable text selection
            in_button_touch = true;
        }
    });
    document.addEventListener('touchend', function(e) {
        all_key_ids.map((id) => {
            document.getElementById(id).style.pointerEvents = null;
        });
        if (in_button_touch) {
            if (all_key_ids.includes(e.target.id)) {
                // Disable text selection and triggering of click event.
                e.preventDefault();
            }
            in_button_touch = false;
        }
    });
  "))
)
