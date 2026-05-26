from scripts.dotlocal_lib import tiers


def test_explicit_tier_wins():
    assert tiers.resolve_tier("anything", {"netlocal.tier": "5"}) == 5


def test_component_label_maps_to_tier():
    assert tiers.resolve_tier("step-ca", {"netlocal.component": "ca"}) == 0
    assert tiers.resolve_tier("postgres", {"netlocal.component": "db"}) == 1
    assert tiers.resolve_tier("caddy", {"netlocal.component": "gateway"}) == 3
    assert tiers.resolve_tier("loki", {"netlocal.component": "log"}) == 5


def test_unlabelled_service_falls_through_to_heuristic_or_default():
    # Heuristic: name contains "dns" → backbone (T0).
    assert tiers.resolve_tier("coredns", {}) == 0
    # Pure unknown: default tier.
    assert tiers.resolve_tier("custom-app", {}) == tiers.DEFAULT_TIER


def test_labels_list_form_is_parsed():
    labels = tiers.labels_from_compose_service({
        "labels": ["netlocal.component=db", "other=value"],
    })
    assert labels["netlocal.component"] == "db"
    assert labels["other"] == "value"


def test_labels_dict_form_is_parsed():
    labels = tiers.labels_from_compose_service({"labels": {"netlocal.component": "cache"}})
    assert labels == {"netlocal.component": "cache"}


def test_group_by_tier_sorts_ascending():
    assignments = [
        tiers.TierAssignment("app", 4),
        tiers.TierAssignment("postgres", 1),
        tiers.TierAssignment("dns", 0),
    ]
    grouped = tiers.group_by_tier(assignments)
    assert [t for t, _ in grouped] == [0, 1, 4]
