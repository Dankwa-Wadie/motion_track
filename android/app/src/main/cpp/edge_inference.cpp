#include "edge_inference.h"
#include "edge_impulse_sdk/classifier/ei_run_classifier.h"
#include <stdio.h>

extern "C" {

// This function will be called from Dart
float run_inference(float x, float y, float z) {
    signal_t signal;
    ei_impulse_result_t result = {0};

    // Create input buffer
    float features[] = {x, y, z};
    numpy::signal_from_buffer(features, sizeof(features)/sizeof(float), &signal);

    // Run the classifier
    EI_IMPULSE_ERROR res = run_classifier(&signal, &result, false);
    if (res != EI_IMPULSE_OK) {
        printf("Error running classifier (%d)\n", res);
        return -1.0f;
    }

    // Return top prediction value
    return result.classification[0].value;
}

}
