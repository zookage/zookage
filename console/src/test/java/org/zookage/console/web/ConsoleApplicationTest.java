/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.zookage.console.web;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

@QuarkusTest
class ConsoleApplicationTest {
  @Test
  void rendersHelloWorldHomePage() {
    given()
        .when()
        .get("/")
        .then()
        .statusCode(200)
        .body(containsString("ZooKage Console"))
        .body(containsString("Hello World"));
  }

  @Test
  void returnsLiveHealthStatus() {
    given()
        .accept("application/json")
        .when()
        .get("/q/health/live")
        .then()
        .statusCode(200)
        .body("status", equalTo("UP"))
        .body("checks[0].name", equalTo("console-live"))
        .body("checks[0].status", is("UP"));
  }

  @Test
  void returnsReadyHealthStatus() {
    given()
        .accept("application/json")
        .when()
        .get("/q/health/ready")
        .then()
        .statusCode(200)
        .body("status", equalTo("UP"))
        .body("checks[0].name", equalTo("console-ready"))
        .body("checks[0].status", is("UP"));
  }
}
