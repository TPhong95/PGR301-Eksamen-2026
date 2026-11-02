package no.pgr301.exam.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import no.pgr301.exam.model.AnalyzeResponse;
import no.pgr301.exam.model.GiftAnalysis;
import org.springframework.stereotype.Service;

@Service
public class WishlistService {

  private static final Set<String> KNOWN_ROOMS =
      Set.of("stue", "kjøkken", "soverom", "barnerom", "garasje", "kontor", "bad");

  private static final Set<String> KNOWN_GIFTS =
      Set.of(
          "leketøy",
          "bøker",
          "klær",
          "sport",
          "hjem",
          "kjøkken",
          "elektronikk",
          "hobby",
          "skjønnhet",
          "mat-og-drikke",
          "reise",
          "kunst-og-design",
          "dyr");

  private final S3Service s3;
  private final RekognitionService rekognition;
  private final BedrockService bedrock;
  private final MeterRegistry registry;
  private final DistributionSummary suggestionsPerRequest;
  private final DistributionSummary imageBytes;

  public WishlistService(
      S3Service s3,
      RekognitionService rekognition,
      BedrockService bedrock,
      MeterRegistry registry) {
    this.s3 = s3;
    this.rekognition = rekognition;
    this.bedrock = bedrock;
    this.registry = registry;
    this.suggestionsPerRequest =
        DistributionSummary.builder("wishapp.suggestions.per_request")
            .description("Number of gift suggestion per analysis")
            .register(registry);

    this.imageBytes =
        DistributionSummary.builder("wishapp.image.bytes")
            .description("Size of uploaded image in bytes")
            .baseUnit("bytes")
            .register(registry);
  }

  public AnalyzeResponse process(byte[] bytes, String filename, String contentType) {
    imageBytes.record(bytes.length);
    String s3Key = s3.upload(bytes, filename, contentType);
    List<String> labels = rekognition.detectLabels(bytes);
    GiftAnalysis analysis = bedrock.suggestGifts(labels);

    suggestionsPerRequest.record(analysis.suggestions().size());
    recordRoomCategory(analysis.roomCategory());
    analysis.suggestions().forEach(s -> recordGiftCategory(s.giftCategory()));

    return new AnalyzeResponse(
        s3Key,
        labels,
        analysis.roomAnalysis(),
        analysis.roomCategory(),
        analysis.recipientProfile(),
        analysis.suggestions(),
        Instant.now().toString());
  }

  private void recordRoomCategory(String roomCategory) {
    String category = normalize(roomCategory, KNOWN_ROOMS);
    Counter.builder("wishapp.rooms.analyzed")
        .description("Images analyzed per room category")
        .tag("category", category)
        .register(registry)
        .increment();
  }

  private void recordGiftCategory(String giftCategory) {
    String category = normalize(giftCategory, KNOWN_GIFTS);
    Counter.builder("wishapp.gifts.suggested")
        .description("Gift suggestions per gift category")
        .tag("category", category)
        .register(registry)
        .increment();
  }

  private static String normalize(String value, Set<String> allowed) {
    if (value == null || value.isBlank()) {
      return "ukjent";
    }
    String v = value.trim().toLowerCase();
    if (!allowed.contains(v)) {
      return "ukjent";
    }
    return v;
  }
}
