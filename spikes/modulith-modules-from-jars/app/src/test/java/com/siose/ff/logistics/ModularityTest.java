package com.siose.ff.logistics;
import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModule;
import org.springframework.modulith.core.ApplicationModules;
class ModularityTest {
  ApplicationModules modules = ApplicationModules.of(LogisticsApplication.class);
  @Test void findsTheModulesInTheJars() {
    modules.forEach(m -> System.out.println("MODULE " + m.getIdentifier() + " types=" + m.getBasePackage().stream().count()
        + " deps=" + m.getDirectDependencies(modules).stream().map(d -> d.getTargetModule().getIdentifier().toString()).toList()));
    assertThat(modules.stream().map(m -> m.getIdentifier().toString())).containsExactlyInAnyOrder("alpha", "beta");
    assertThat(modules.getModuleByName("beta").orElseThrow().contains(com.siose.ff.logistics.beta.adapter.AlphaAnswerLookup.class)).isTrue();
  }
  @Test void verifies() { modules.verify(); }
}
