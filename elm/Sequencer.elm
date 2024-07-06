port module Sequencer exposing (Model, Msg(..), update, initModel, view)

import Array exposing (Array)
import Debug exposing (toString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import String exposing (toInt)
import WebAudio exposing (oscillator)
import DrumMachine exposing (Msg(..))


port transmitMelody : List (List Float) -> Cmd msg


port transmitWave : String -> Cmd msg


type alias Model =
    { melody : Array Chord, activeChord : Int, oscillator : Oscillator, bpm : Int }


type Msg
    = SetNote ( Int, Int, NoteDefinition )
    | UpdateOscillator OscillatorUpdate
    | UpdateActiveColumn Int
    | Play -- TODO: this will be global
    | Pause -- TODO: this will be global
    | Reset -- TODO: this will be global
    | UpdateBpm Int -- TODO: this will be global


view : Model -> Html Msg
view model =
    sequencerCard model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Play ->
            ( model, Cmd.none )

        Pause ->
            ( model, Cmd.none )

        Reset ->
            ( model, Cmd.none )

        UpdateBpm bpm ->
            ( { model | bpm = bpm }, Cmd.none )

        UpdateActiveColumn columnNumber ->
            ( { model | activeChord = columnNumber }, Cmd.none ) 

        SetNote ( rowNumber, columnNumber, noteDefinition ) ->
            case Array.get columnNumber model.melody of
                Maybe.Just chord ->
                    let
                        updatedChord =
                            Array.set rowNumber noteDefinition chord
                    in
                    let
                        updatedMelody =
                            Array.set columnNumber updatedChord model.melody
                    in
                    let
                        updatedModel =
                            { model | melody = updatedMelody }
                    in
                    ( updatedModel, transmitMelody (melodyFrequencies updatedModel) )

                Maybe.Nothing ->
                    ( model, Cmd.none )

        UpdateOscillator NextWave ->
            let
                oscillator =
                    model.oscillator
            in
            ( { model | oscillator = { oscillator | wave = nextWave oscillator.wave } }, transmitWave (stringOfWave (nextWave oscillator.wave)) )

        UpdateOscillator PrevWave ->
            let
                oscillator =
                    model.oscillator
            in
            ( { model | oscillator = { oscillator | wave = prevWave oscillator.wave } }, transmitWave (stringOfWave (prevWave oscillator.wave)) )


type NoteDefinition
    = NotPopulated
    | Populated Note


type alias Chord =
    Array NoteDefinition


type Wave
    = Sine
    | Square
    | Triangle


type alias Oscillator =
    { wave : Wave }


type OscillatorUpdate
    = NextWave
    | PrevWave


type Note
    = C
    | D
    | E
    | F
    | G
    | A
    | B


initModel : Model
initModel =
    { melody = Array.repeat 8 (Array.repeat 8 NotPopulated)
    , activeChord = 0
    , oscillator = { wave = Sine }
    , bpm = 200
    }


nextWave : Wave -> Wave
nextWave wave =
    case wave of
        Sine ->
            Square

        Square ->
            Triangle

        Triangle ->
            Sine


prevWave : Wave -> Wave
prevWave wave =
    case wave of
        Square ->
            Sine

        Triangle ->
            Square

        Sine ->
            Triangle


stringOfWave : Wave -> String
stringOfWave wave =
    case wave of
        Sine ->
            "Sine"

        Square ->
            "Square"

        Triangle ->
            "Triangle"


chordToFrequencies : List NoteDefinition -> List Float
chordToFrequencies noteDefinitions =
    List.filter isNote noteDefinitions
        |> List.map
            (\note ->
                case note of
                    Populated C ->
                        261.63

                    Populated D ->
                        293.66

                    Populated E ->
                        329.63

                    Populated F ->
                        349.23

                    Populated G ->
                        392.0

                    Populated A ->
                        440.0

                    Populated B ->
                        493.88

                    NotPopulated ->
                        -1.0
            )


melodyFrequencies : Model -> List (List Float)
melodyFrequencies model =
    model.melody
        |> Array.map Array.toList
        |> Array.toList
        |> List.map (\chord -> chordToFrequencies chord)


freqencyOfNote : Note -> Float
freqencyOfNote _ =
    0.0


isNote : NoteDefinition -> Bool
isNote note =
    case note of
        Populated _ ->
            True

        NotPopulated ->
            False


isNotePopulated : Model -> Int -> Int -> Bool
isNotePopulated model rowNumber columnNumber =
    case Array.get columnNumber model.melody of
        Maybe.Just chord ->
            case Array.get rowNumber chord of
                Maybe.Just (Populated _) ->
                    True

                Maybe.Just NotPopulated ->
                    False

                Maybe.Nothing ->
                    False

        Maybe.Nothing ->
            False


createNote : Int -> Int -> Model -> Html Msg
createNote rowNumber columnNumber model =
    div
        [ onClick
            (SetNote
                ( rowNumber
                , columnNumber
                , if isNotePopulated model rowNumber columnNumber then
                    NotPopulated

                  else
                    case rowNumber of
                        0 ->
                            Populated G

                        1 ->
                            Populated F

                        2 ->
                            Populated E

                        3 ->
                            Populated D

                        4 ->
                            Populated C

                        5 ->
                            Populated B

                        6 ->
                            Populated A

                        _ ->
                            Populated A
                )
            )
        , class "note"
        , attribute "data-enabled"
            (if isNotePopulated model rowNumber columnNumber then
                "true"

             else
                "false"
            )
        ]
        []


createChord : Int -> Int -> Int -> Model -> List (Html Msg)
createChord currNote maxNotes columnNumber model =
    if maxNotes == currNote then
        []

    else
        createNote currNote columnNumber model :: createChord (currNote + 1) maxNotes columnNumber model


chordView : Int -> Model -> Html Msg
chordView columnNumber model =
    div
        [ class "chord"
        , attribute "data-on"
            (if model.activeChord == columnNumber then
                "true"

             else
                "false"
            )
        ]
        (createChord 0 8 columnNumber model)


playView : Model -> Html Msg
playView model =
    div [ class "ctrl" ]
        [ div [ class "play", onClick Play ] [ text "▶️" ]
        , div [ class "pause", onClick Pause ] [ text "⏸️" ]
        , div [ class "reset", onClick Reset ] [ text "⏮️" ]
        , input
            [ class "bpm"
            , type_ "text"
            , placeholder (toString model.bpm)
            , value (toString model.bpm)
            , onInput
                (\bpm ->
                    case toInt bpm of
                        Maybe.Just v ->
                            UpdateBpm v

                        Maybe.Nothing ->
                            UpdateBpm model.bpm
                )
            ]
            []
        ]


determineActiveX : Model -> String
determineActiveX model =
    toString (5 + model.activeChord * 37) ++ "px"


displayWave : Model -> String
displayWave model =
    stringOfWave model.oscillator.wave


sequencerCard : Model -> Html Msg
sequencerCard model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "🧮 Sequencer" ]
        , div [ class "playbar" ] [ div [ class "activenote", style "left" (determineActiveX model) ] [ text "⬇️" ] ]
        , chordView 0 model
        , chordView 1 model
        , chordView 2 model
        , chordView 3 model
        , chordView 4 model
        , chordView 5 model
        , chordView 6 model
        , chordView 7 model
        , playView model
        ]
