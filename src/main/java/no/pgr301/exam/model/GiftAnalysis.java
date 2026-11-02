package no.pgr301.exam.model;

import java.util.List;

public record GiftAnalysis(
    String roomAnalysis,
    String roomCategory,
    String recipientProfile,
    List<GiftSuggestion> suggestions) {}
