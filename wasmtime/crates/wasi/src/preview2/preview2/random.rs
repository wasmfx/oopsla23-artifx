use crate::preview2::wasi::random::insecure;
use crate::preview2::wasi::random::insecure_seed;
use crate::preview2::wasi::random::random;
use crate::preview2::WasiView;
use cap_rand::{distributions::Standard, Rng};

#[async_trait::async_trait]
impl<T: WasiView> random::Host for T {
    async fn get_random_bytes(&mut self, len: u64) -> anyhow::Result<Vec<u8>> {
        Ok((&mut self.ctx_mut().random)
            .sample_iter(Standard)
            .take(len as usize)
            .collect())
    }

    async fn get_random_u64(&mut self) -> anyhow::Result<u64> {
        Ok(self.ctx_mut().random.sample(Standard))
    }
}

#[async_trait::async_trait]
impl<T: WasiView> insecure::Host for T {
    async fn get_insecure_random_bytes(&mut self, len: u64) -> anyhow::Result<Vec<u8>> {
        Ok((&mut self.ctx_mut().insecure_random)
            .sample_iter(Standard)
            .take(len as usize)
            .collect())
    }

    async fn get_insecure_random_u64(&mut self) -> anyhow::Result<u64> {
        Ok(self.ctx_mut().insecure_random.sample(Standard))
    }
}

#[async_trait::async_trait]
impl<T: WasiView> insecure_seed::Host for T {
    async fn insecure_seed(&mut self) -> anyhow::Result<(u64, u64)> {
        let seed: u128 = self.ctx_mut().insecure_random_seed;
        Ok((seed as u64, (seed >> 64) as u64))
    }
}
