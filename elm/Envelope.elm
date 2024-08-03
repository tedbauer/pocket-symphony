port module Envelope exposing (..)

import Html exposing (Html, div, li, text, tr, track, ul)
import Html.Attributes exposing (class, height, width)
import Html.Events exposing (onClick, onMouseDown)
import Svg exposing (line, svg)


type alias Model =
    { attack : Float
    , sustain : Float
    , decay : Float
    , release : Float
    }



-- MODEL


init : Model
init =
    { attack = 0
    , sustain = 0
    , decay = 0
    , release = 0
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "✉️ Envelope" ]
        , div [ class "envelope" ]
            [ div [ class "envelopecontrol" ]
                [ text "Attack"
                , div [ class "envelopecontrolslider", onClick (SetAttack (model.attack + 1)) ]
                    [ text (String.fromFloat model.attack)
                    ]
                ]
            , div [ class "envelopecontrol" ]
                [ text "Sustain"
                , div [ class "envelopecontrolslider" ]
                    [ text (String.fromFloat model.sustain)
                    ]
                ]
            , div [ class "envelopecontrol" ]
                [ text "Decay"
                , div [ class "envelopecontrolslider" ]
                    [ text (String.fromFloat model.decay)
                    ]
                ]
            , div [ class "envelopecontrol" ]
                [ text "Release"
                , div [ class "envelopecontrolslider" ]
                    [ text (String.fromFloat model.release)
                    ]
                ]
            ]
        ]



-- UPDATE


type Msg
    = SetAttack Float
    | SetSustain Float
    | SetDecay Float
    | SetRelease Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetAttack attack ->
            ( { model | attack = attack }, transmitAttack (round attack) )

        SetSustain sustain ->
            ( { model | sustain = sustain }, transmitSustain (round sustain) )

        SetDecay decay ->
            ( { model | decay = decay }, transmitDecay (round decay) )

        SetRelease release ->
            ( { model | release = release }, transmitRelease (round release) )



-- PORTS


port transmitAttack : Int -> Cmd msg


port transmitSustain : Int -> Cmd msg


port transmitDecay : Int -> Cmd msg


port transmitRelease : Int -> Cmd msg
