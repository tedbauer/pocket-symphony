port module SoundEngineController exposing (..)

import Json.Encode as Encode


type alias EngineMessage =
    { tag : String, message : String }


encode_melody : List (List Float) -> EngineMessage
encode_melody melody =
    { tag = "melody", message = Encode.encode 0 (Encode.list (Encode.list Encode.float) melody) }


encode_delay : String -> Float -> EngineMessage
encode_delay param time =
    { tag = "delay", message = Encode.encode 0 (Encode.object [ ( "param", Encode.string param ), ( "value", Encode.float time ) ]) }


encode_bpm_message : Int -> EngineMessage
encode_bpm_message bpm =
    { tag = "bpm"
    , message = Encode.encode 0 (Encode.int bpm)
    }


encode_audio_command_message : String -> EngineMessage
encode_audio_command_message command =
    { tag = "audio_command"
    , message = Encode.encode 0 (Encode.string command)
    }


encode_envelope : String -> Float -> EngineMessage
encode_envelope param value =
    { tag = "envelope"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string param ), ( "value", Encode.float value ) ])
    }


encode_lfo_frequency : Float -> EngineMessage
encode_lfo_frequency freq =
    { tag = "lfo"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "frequency" ), ( "value", Encode.float freq ) ])
    }


encode_oscillator_waveform : String -> EngineMessage
encode_oscillator_waveform waveform =
    { tag = "oscillator"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "waveform" ), ( "value", Encode.string waveform ) ])
    }


encode_oscillator_coarse_frequency : Float -> EngineMessage
encode_oscillator_coarse_frequency freq =
    { tag = "oscillator"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "coarseFrequency" ), ( "value", Encode.float freq ) ])
    }


encode_oscillator_fine_frequency : Float -> EngineMessage
encode_oscillator_fine_frequency freq =
    { tag = "oscillator"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "fineFrequency" ), ( "value", Encode.float freq ) ])
    }


encode_oscillator_octave : Int -> EngineMessage
encode_oscillator_octave octave =
    { tag = "oscillator"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "octave" ), ( "value", Encode.int octave ) ])
    }


encode_lfo_intensity : Float -> EngineMessage
encode_lfo_intensity intensity =
    { tag = "lfo"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "intensity" ), ( "value", Encode.float intensity ) ])
    }


encode_lfo_wave_type : String -> EngineMessage
encode_lfo_wave_type waveType =
    { tag = "lfo"
    , message = Encode.encode 0 (Encode.object [ ( "param", Encode.string "waveType" ), ( "value", Encode.string waveType ) ])
    }


port stepEngine : EngineMessage -> Cmd msg
