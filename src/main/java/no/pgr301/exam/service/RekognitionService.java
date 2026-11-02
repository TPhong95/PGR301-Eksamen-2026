package no.pgr301.exam.service;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.util.List;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.rekognition.RekognitionClient;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsRequest;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsResponse;
import software.amazon.awssdk.services.rekognition.model.Image;
import software.amazon.awssdk.services.rekognition.model.Label;

@Service
public class RekognitionService {

  private final RekognitionClient client;
  private final Timer callTimer;

  public RekognitionService(RekognitionClient client, MeterRegistry registry) {
    this.client = client;
    this.callTimer =
        Timer.builder("wishapp.rekognition.duration")
            .description("Time spent in call function detectLabels")
            .register(registry);
  }

  public List<String> detectLabels(byte[] bytes) {
    DetectLabelsResponse resp =
        callTimer.record(
            () ->
                client.detectLabels(
                    DetectLabelsRequest.builder()
                        .image(Image.builder().bytes(SdkBytes.fromByteArray(bytes)).build())
                        .maxLabels(20)
                        .minConfidence(70f)
                        .build()));

    return resp.labels().stream().map(Label::name).toList();
  }
}
