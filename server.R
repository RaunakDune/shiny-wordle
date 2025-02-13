library(shiny)
library(htmltools)
#library(rsconnect)

source("tomble_wordlist.R")

function(input, output) {
  target_word <- reactiveVal(sample(words_common, 1))
  all_guesses <- reactiveVal(list())
  finished <- reactiveVal(FALSE)
  current_guess_letters <- reactiveVal(character(0))

  reset_game <- function() {
    target_word(sample(words_common, 1))
    all_guesses(list())
    finished(FALSE)
  }


  observeEvent(input$Enter, {
    guess <- paste(current_guess_letters(), collapse = "")

    if (! guess %in% words_all)
      return()

    # if (input$hard) {
    # # Letters in the target word that the player has previously
    # # guessed correctly.
    # matched_letters = used_letters().intersection(set(target_word()))
    # if not set(guess).issuperset(matched_letters):
    #     return
    # }

    all_guesses_new <- all_guesses()

    check_result <- check_word(guess, target_word())
    all_guesses_new[[length(all_guesses_new) + 1]] <- check_result
    all_guesses(all_guesses_new)

    if (isTRUE(check_result$win)) {
        finished(TRUE)
    }

    current_guess_letters(character(0))
  })

  output$previous_guesses <- renderUI({
    res <- lapply(all_guesses(), function(guess) {
      letters <- guess$letters
      row <- mapply(
        letters,
        guess$matches,
        FUN = function(letter, match) {
          # This will have the value "correct", "in-word", or "not-in-word", and
          # those values are also used as CSS class names.
          match_type <- match
          div(toupper(letter), class = paste("letter", match_type))
        },
        SIMPLIFY = FALSE,
        USE.NAMES = FALSE
      )
      div(class = "word", row)
    })

    scroll_js <- "
        document.querySelector('.guesses')
          .scrollTo(0, document.querySelector('.guesses').scrollHeight);
    "
    tagList(res, tags$script(HTML(scroll_js)))
  })

  output$current_guess <- renderUI({
    if (finished()) return()

    letters <- current_guess_letters()

    # Fill in blanks for letters up to length of target word. If letters is:
    #   "a" "r"
    # then result is:
    #   "a" "r" "" "" ""
    target_length <- isolate(nchar(target_word()))
    if (length(letters) < target_length) {
      letters[(length(letters)+1) : target_length] <- ""
    }

    div(
      class = "word",
      lapply(letters, function(letter) {
        div(toupper(letter), class ="letter guess")
      })
    )
  })

  output$new_game_ui <- renderUI({
    if (!finished())
      return()

    actionButton("new_game", "New Game")
  })

  observeEvent(input$new_game, {
    reset_game()
  })

  used_letters <- reactive({
    # This is a named list. The structure will be something like:
    # list(p = "not-in-word", a = "in-word", e = "correct")
    letter_matches <- list()

    # Populate `letter_matches` by iterating over all letters in all the guesses.
    lapply(all_guesses(), function(guess) {
      mapply(guess$letters, guess$matches, SIMPLIFY = FALSE, USE.NAMES = FALSE,
        FUN = function(letter, match) {
          prev_match <- letter_matches[[letter]]
          if (is.null(prev_match)) {
            # If there isn't an existing entry for that letter, just use it.
            letter_matches[[letter]] <<- match
          } else {
            # If an entry is already present, it can be "upgraded":
            # "not-in-word" < "in-word" < "correct"
            if (match == "correct" && prev_match %in% c("not-in-word", "in-word")) {
              letter_matches[[letter]] <<- match
            } else if (match == "in-word" && prev_match == "not-in-word") {
              letter_matches[[letter]] <<- match
            }
          }
        }
      )
    })

    letter_matches
  })


  keys <- list(
    c("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"),
    c("A", "S", "D", "F", "G", "H", "J", "K", "L"),
    c("Enter", "Z", "X", "C", "V", "B", "N", "M", "Back")
  )

  output$keyboard <- renderUI({
    prev_match_type <- used_letters()
    keyboard <- lapply(keys, function(row) {
      row_keys <- lapply(row, function(key) {
        class <- "key"
        key_lower <- tolower(key)
        if (!is.null(prev_match_type[[key_lower]])) {
          class <- c(class, prev_match_type[[key_lower]])
        }
        if (key %in% c("Enter", "Back")) {
          class <- c(class, "wide-key")
        }
        actionButton(key, key, class = class)
      })
      div(class = "keyboard-row", row_keys)
    })

    div(class = "keyboard", keyboard)
  })

  # Add listeners for each key, except Enter and Back
  lapply(unlist(keys, recursive = FALSE), function(key) {
    if (key %in% c("Enter", "Back")) return()
    observeEvent(input[[key]], {
      if (finished())
        return()
      cur <- current_guess_letters()
      if (length(cur) >= 5)
        return()
      current_guess_letters(c(cur, tolower(key)))
    })
  })

  observeEvent(input$Back, {
    if (length(current_guess_letters()) > 0) {
      current_guess_letters(current_guess_letters()[-length(current_guess_letters())])
    }
  })


  output$endgame <- renderUI({
    if (!finished())
      return()

    lines <- lapply(all_guesses(), function(guess) {
      line <- vapply(guess$matches, function(match) {
        switch(match,
          "correct" = "🟩",
          "in-word" = "🟨",
          "not-in-word" = "⬜"
        )
      }, character(1))

      div(paste(line, collapse = ""))
    })

    div(class = "endgame-content", lines)
  })

}

check_word <- function(guess_str, target_str) {
  guess <- strsplit(guess_str, "")[[1]]
  target <- strsplit(target_str, "")[[1]]
  remaining <- character(0)

  if (length(guess) != length(target)) {
    stop("Word lengths don't match.")
  }

  result <- rep("not-in-word", length(guess))

  # First pass: find matches in correct position. Letters in the target that do
  # not match the guess are added to the remaining list.
  for (i in seq_along(guess)) {
    if (guess[i] == target[i]) {
      result[i] <- "correct"
    } else {
      remaining <- c(remaining, target[i])
    }
  }

  for (i in seq_along(guess)) {
    if (guess[i] != target[i] && guess[i] %in% remaining) {
      result[i] <- "in-word"
      remaining <- remaining[-match(guess[i], remaining)]
    }
  }

  list(
    word = guess_str,
    letters = guess,
    matches = result,
    win = all(result == "correct")
  )
}
