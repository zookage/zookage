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

package io.zookage.spark.ui;

public final class SpnegoAuthenticationFilterTest {
  private SpnegoAuthenticationFilterTest() {}

  public static void main(String[] args) {
    expectUser("zookage@ZOOKAGE.LOCAL", "zookage");
    expectRejected("zookage/host@ZOOKAGE.LOCAL");
    expectRejected("zookage@OTHER.LOCAL");
    expectRejected("@ZOOKAGE.LOCAL");
    expectRejected("zookage");
  }

  private static void expectUser(String principal, String expected) {
    String actual = SpnegoAuthenticationFilter.shortUserName(principal, "ZOOKAGE.LOCAL");
    if (!expected.equals(actual)) {
      throw new AssertionError(principal + " mapped to " + actual + ", expected " + expected);
    }
  }

  private static void expectRejected(String principal) {
    String actual = SpnegoAuthenticationFilter.shortUserName(principal, "ZOOKAGE.LOCAL");
    if (actual != null) {
      throw new AssertionError(principal + " unexpectedly mapped to " + actual);
    }
  }
}
