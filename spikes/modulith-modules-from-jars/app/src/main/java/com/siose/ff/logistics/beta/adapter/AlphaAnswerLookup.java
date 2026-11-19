package com.siose.ff.logistics.beta.adapter;
public class AlphaAnswerLookup implements com.siose.ff.logistics.beta.AnswerLookup {
  private final com.siose.ff.logistics.alpha.AlphaService alpha = new com.siose.ff.logistics.alpha.AlphaService();
  public int answer() { return alpha.answer(); }
}
